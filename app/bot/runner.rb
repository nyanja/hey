# frozen_string_literal: true

module Bot
  class Runner
    attr_reader :core, :query

    extend Forwardable
    def_delegators :core, :driver, :config
    # def_delegators :driver, :click

    include Helpers::Logger
    include Helpers::Wait
    include Helpers::Sites
    include Helpers::Queries
    include Helpers::Results

    include Scenarios::Single

    def apply_target_behavior result, target_type
      if config.skip_target && !result.text.match?(config.target_patterns.first)
        log :"#{target_type}_target", "Пропуск неосновного сайта"
        return
      end
      n = determine_explore_deepness! result
      log :"#{target_type}_target", "глубина = #{n}"
      css = (".organic__path .link:last-of-type" if config.last_path_link_target?)
      visit result, config.pre_delay_target, css
      return if n.zero?
      n.times do |i|
        start_time = Time.now.to_i
        wait 3
        print "  "
        scroll(:target) while (driver.scroll_height - 10) >= driver.y_offset
        puts
        rest = (start_time + config.min_visit_target) - Time.now.to_i
        if rest.positive?
          wait rest / 8
          driver.scroll_to 0
          rest = (start_time + config.min_visit_target) - Time.now.to_i
          wait rest if rest.positive?
        end
        if n != i.succ
          # wait(:explore_delay)
          visit_some_link
        end
      rescue Selenium::WebDriver::Error::NoSuchElementError
        log(:error, "Нет подходящей ссылки для перехода")
      end
    end

    def determine_explore_deepness! result
      return 0 unless unique_ip? result
      config.explore_deepness
    end

    def apply_rival_behavior result, status
      return unless unique_ip? result
      scroll_percent = config.scroll_height_non_target
      log(:non_target, "прокрутка #{scroll_percent}%")
      css = (".organic__path .link:last-of-type" if config.last_path_link_rival?)
      visit result, config.pre_delay_non_target, css
      return if scroll_percent.nil? || scroll_percent.zero?
      start_time = Time.now.to_i
      wait 10
      driver.js "window.stop()"
      print "  "
      scroll while (driver.scroll_height * 0.01 * scroll_percent) > driver.y_offset
      puts
      if config.min_visit_non_target + start_time > Time.now.to_i
        wait((config.min_visit_non_target + start_time) - Time.now.to_i)
      end

      additional_visits if status == :rival
    end

    def unique_ip? result
      return true unless config.unique_visit_ip?
      d = domain(result)
      if Ip.current == Storage.get(d)
        log(:info, "#{d}: Посещение с таким IP уже было")
        false
      else
        Storage.set(d, Ip.current)
        true
      end
    end

    def visit_some_link
      link = some_link
      return unless link
      log(:link, link.text)
      driver.scroll_to(link.location.y - rand(120..220))
      wait :avg
      link.click
    end

    # def scroll is_target = nil
    #   scroll_amount = is_target ? config.scroll_amount_target : config.scroll_amount
    #   amount = if config.scroll_threshold &.< driver.scroll_height
    #              scroll_amount * config.scroll_multiplier
    #            else
    #              scroll_amount
    #            end
    #   driver.scroll_by amount, is_target
    #   print "."
    #   sleep is_target ? config.scroll_delay_target : config.scroll_delay
    # rescue Selenium::WebDriver::Error::TimeOutError
    #   print "x"
    # end

    def domain result
      result.find_element(css: ".organic__subtitle .link b, " \
                               ".organic__subtitle .link, " \
                               ".serp-title_type_subtitle .link").text
    rescue Selenium::WebDriver::Error::NoSuchElementError => e
      # binding.pry
      log :error, "Нетипичная ссылка #{self.class}"
      puts e.backtrace
      "unknow"
    end
  end
end
