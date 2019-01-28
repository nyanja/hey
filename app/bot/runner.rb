# frozen_string_literal: true

module Bot
  class Runner
    attr_reader :core, :query

    extend Forwardable
    def_delegators :core, :driver, :config
    def_delegators :driver, :click

    include Helpers::Logger
    include Helpers::Wait
    include Helpers::Sites
    include Helpers::Queries
    include Helpers::Results

    include Scenarios::Single

    def initialize core, query
      @core = core
      @query = query

      @verified_results = []
      @actual_index = 0

      @non_pseudos = []
      @targets = []
      @target_domains = []
      @rivals = []
    end

    def lite_scenario
      return if query_delayed?
      search
      parse_results(search_results) && lite_process_query
      driver.quit
      wait(:query_delay)
    rescue Selenium::WebDriver::Error::NoSuchElementError => e
      log(:error, "Нетипичная страница поиска")
      puts e.inspect
      driver.quit
    end

    def default_scenario
      case query
      when %r{^https?:\/\/}
        single_scenario
        wait(:query_delay)
        return
      when %r{\/}
        right_clicks_scenario
        wait(:query_delay)
        return
      end

      return if query_delayed? ||
                query_limited?

      search
      parse_results(search_results) && process_query
      driver.quit
      wait(:query_delay)
    rescue Selenium::WebDriver::Error::NoSuchElementError => e
      log(:error, "Нетипичная страница поиска")
      puts e.inspect
      driver.quit
    end

    def parse_results results
      results = remove_skips_from!(results)
      results = results.take(config.results_limit || results.size)
      results.each_with_index do |result, i|
        if non_pseudo?(result)
          @non_pseudos << i + 1
        elsif result.text.match?(config.target)
          @targets << i + 1
        elsif config.non_target && result.text.match?(config.non_target)
          @rivals << i + 1
        end
      end

      @pseudo = (if !@targets.empty?
                   config.pseudo_targets
                 else
                   config.sole_pseudo_targets || pseudo_targets
                 end || []).map do |v|
                   return v unless config.results_limit
                   [v, config.results_limit].min
                 end

      next_pseudo!

      return if try_to_defer_query

      main = []

      results.each_with_index do |result, i|
        @actual_index = i + 1

        break if no_more_targets_below?

        status = target?(result) ||
                 pseudo? ||
                 (config.mode == 1 && rival?(result)) ||
                 (config.mode == 1 && skip?)
        if status == :main
          main << [result, status, @actual_index]
        else
          @verified_results << [result, status, @actual_index]
        end
      end
      @verified_results += main
    end

    def next_pseudo! last_index = nil
      key = !@targets.empty? ? "spsdk" : "psdk"
      p = [Storage.get(key).to_i, @pseudo.min - 1].max
      np = p + 1 > @pseudo.max ? @pseudo.min : (p + 1)
      Storage.set(key, np)
      actual = np + @targets.last.to_i
      if last_index == np
        @pseudos = []
      elsif @non_pseudos.include?(actual) || @rivals.include?(actual)
        next_pseudo! np
      else
        @pseudos = [np]
      end
    end

    def try_to_defer_query
      return unless no_target_on_the_page? ||
                    targets_on_top? ||
                    (config.mode == 1 && non_pseudos_below_pseudo?)
      defer_query
      true
    end

    def no_target_on_the_page?
      return unless @targets.empty? && config.query_skip_on_presence?
      log(:skip!, "Продвигаемого сайта нет на странице")
      true
    end

    def targets_on_top?
      return unless @targets.first &&
                    config.query_skip_on_position_by_limit &&
                    @targets.first <= config.query_skip_on_position_by_limit.to_i
      log(:skip!, "Продвигаемый сайт уже на высокой позиции")
      if config.query_skip_after_perform?
        defer_query
        nil
      else
        true
      end
    end

    def non_pseudos_below_pseudo?
      return unless config.query_skip_on_non_pseudos_below_pseudo? &&
                    @targets.last.to_i + @pseudo.max.to_i <= @non_pseudos.min.to_i
      log(:skip!, "Сайты к пропуску ниже доп. целевого")
      true
    end

    def target?(result)
      return unless @targets.include? @actual_index
      d = domain(result)
      return :skip if @target_domains.include? d
      @target_domains << d
      :main
    end

    def non_pseudo? result
      config.skip_site && result.text.match?(config.skip_site)
    end

    def pseudo?
      return unless @pseudos.include? @actual_index - @targets.last.to_i
      :pseudo
    end

    def rival? result
      return unless config.non_target && result.text.match?(config.non_target)
      :rival
    end

    def skip?
      if @actual_index > config.results_count ||
         (config.skip && !config.non_target)
        :skip
      end
    end

    def invalid? result
      # ignore yandex turbo pages
      result.find_element(class: "overlay_js_intend")
      true
    rescue StandardError
      nil
    end

    def process_query
      count_this_query
      @verified_results.each { |r| parse_result(*r) }
      :pass
    end

    def lite_process_query
      @verified_results.each do |(r, status, info)|
        unless status
          log :skip, domain(r)
          next
        end
        log(:visit, "##{info} #{domain(r)}", "[#{driver&.device}]")
        visit r, 0
      ensure
        driver&.close_tab
        if @t
          d = Time.now - @t
          log :info, "Время: #{d}\n"
          @t = nil
        end
      end
    end

    def skip_result? result
      return unless result.text.match?(config.ignore)
      log(:skip, result.text)
      true
    end

    def parse_result result, status, info
      log(:visit, "##{info} #{domain(result)}", "[#{driver&.device}]")

      if status == :skip
        log(:skip, "Пропуск сайта")
      else
        parse_result_page(result, status)
      end

      wait(:result_delay)
    rescue Selenium::WebDriver::Error::StaleElementReferenceError
      log :error, "Страница неактуальна"
      wait 4
    end

    def parse_result_page result, status
      if status == :rival || (!status && !config.non_target)
        apply_rival_behavior result, status
      elsif status
        apply_target_behavior result, status
      else
        log :skip, "Нейтральный сайт"
      end
    rescue Selenium::WebDriver::Error::NoSuchElementError => e
      puts e.inspect
      log :skip, "Нетипичная ссылка"
    rescue Net::ReadTimeout
      puts
      log :error, "Необрабатываемая страница"
    rescue Selenium::WebDriver::Error::NoSuchWindowError
      puts
      log :error, "Окно было закрыто"
    rescue Selenium::WebDriver::Error::UnknownError
      log :error, e.inspect
    rescue StandardError => e
      raise e.class if e.class == HTTP::ConnectionError
      puts
      log :error, "Ошибка на странице результата", e.inspect
      puts e.backtrace
    ensure
      driver&.close_tab
      if @t
        d = Time.now - @t
        log :info, "Время: #{d}\n"
        @t = nil
      end
    end

    def visit result, delay, css = nil
      driver.scroll_to [(result.location.y - rand(140..300)), 0].max
      sleep 1
      begin
        click({ css: (css || ".organic__url, .organic__link, a") }, result)
        @t = Time.now
      rescue Selenium::WebDriver::Error::NoSuchElementError
        puts "element not found"
      end
      wait delay if delay.positive?
      driver.switch_tab 1
    rescue Selenium::WebDriver::Error::TimeOutError
      puts "stop"
      nil
    end

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

    def scroll is_target = nil
      scroll_amount = is_target ? config.scroll_amount_target : config.scroll_amount
      amount = if config.scroll_threshold &.< driver.scroll_height
                 scroll_amount * config.scroll_multiplier
               else
                 scroll_amount
               end
      driver.scroll_by amount, is_target
      print "."
      sleep is_target ? config.scroll_delay_target : config.scroll_delay
    rescue Selenium::WebDriver::Error::TimeOutError
      print "x"
    end
  end
end
