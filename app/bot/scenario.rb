# frozen_string_literal: true

module Bot
  class Scenario
    attr_reader :core, :query

    extend Forwardable
    def_delegators :core, :driver, :config
    def_delegators :driver, :click

    include Helpers::Logger
    include Helpers::Wait
    include Helpers::Sites
    include Helpers::Queries

    def initialize core, query
      @core = core
      @query = query

      @verified_results = []
      @last_target = nil
      @target_presence = nil
      @actual_index = 0
      @targets_count = 0

      @non_pseudos = []
      @targets = []
      @rivals = []
    end

    def default
      if (t = query_delayed?)
        log :skip, "Запрос отложен. Осталось #{t} мин."
        driver.quit
        wait(:query_delay)
        return
      end

      if query_limited?
        log :skip, "Продвижение неэффективно. Отложим до лучших времен..."
        driver.quit
        wait(:query_delay)
        return
      end

      search
      wait(:min)
      parse_results search_results
      exit_code = try_to_defer_query || process_query
      driver.quit
      wait(:query_delay)
      exit_code
    rescue Selenium::WebDriver::Error::NoSuchElementError => e
      log(:error, "Нетипичная страница поиска")
      puts e.inspect
      driver.quit
    end

    def parse_results results
      results = remove_skips_from!(results)

      results.each_with_index do |result, i|
        if non_pseudo?(result)
          @non_pseudos << i + 1
        elsif result.text.match?(config.target)
          @targets << i + 1
        elsif config.non_target && result.text.match?(config.non_target)
          @rivals << i + 1
        end
      end

      @pseudo = if !@targets.empty?
                  config.pseudo_targets
                else
                  config.sole_pseudo_targets || pseudo_targets
                end || []

      next_pseudo!

      results.each_with_index do |result, i|
        @actual_index = i + 1
        break if @actual_index > config.results_count.to_i &&
                 !@pseudos.empty? &&
                 !@targets.empty?

        break if @actual_index > config.results_limit

        status = target? ||
                 pseudo? ||
                 rival?(result) ||
                 skip?

        @verified_results << [result, status, @actual_index]
      end
      @verified_results
    end

    def next_pseudo!
      key = !@targets.empty? ? "spsdk" : "psdk"
      p = [Storage.get(key).to_i, @pseudo.min - 1].max
      np = p + 1 > @pseudo.max ? @pseudo.min : (p + 1)
      Storage.set(key, np)
      actual = np + @targets.last.to_i
      if @non_pseudos.include?(actual) || @rivals.include?(actual)
        next_pseudo!
      else
        @pseudos = [np]
      end
      puts @rivals, @pseudos
    end

    def remove_skips_from! results
      results.reduce([]) do |acc, result|
        next acc if skip_result?(result) || invalid?(result)
        acc << result
      end
    end

    def try_to_defer_query
      return unless no_target_on_the_page? ||
                    targets_on_top? ||
                    non_targets_below_pseudo?
      defer_query
      true
    end

    def no_target_on_the_page?
      return unless !@target_presence && config.query_skip_on_presence?
      log(:skip!, "Продвигаемого сайта нет на странице")
      true
    end

    def targets_on_top?
      return unless @first_target &&
                    config.query_skip_on_position_by_limit &&
                    @first_target <= config.query_skip_on_position_by_limit.to_i
      log(:skip!, "Продвигаемый сайт уже на высокой позиции")
      true
    end

    def non_targets_below_pseudo?
      return unless config.query_skip_on_non_targets_below_pseudo? &&
                    !@skips_above_pseudo
      log(:skip!, "Сайты к пропуску ниже доп. целевого")
      true
    end

    def target?
      return unless @targets.include? @actual_index
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

    def skip_result? result
      return unless result.text.match?(config.ignore)
      log(:skip, result.text)
      true
    end

    def defer_query
      log(:info, "Запрос отложен на #{config.query_skip_interval} мин.")
      Storage.set "delay//#{query} #{driver&.device}",
                  Time.now.to_i + config.query_skip_interval * 60
    end

    def parse_result result, status, info
      log(:visit, "##{info} #{result.text}", "[#{driver&.device}]")

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
      if status == :rival || (status.nil? && !config.non_target)
        apply_rival_behavior result
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
        log :info, "Задержка: #{d}"
        @t = nil
      end
    end

    def visit result, delay
      driver.scroll_to [(result.location.y - rand(140..300)), 0].max
      sleep 1
      begin
        click({ css: ".organic__url, .organic__link, a" }, result)
        @t = Time.now
      rescue Selenium::WebDriver::Error::NoSuchElementError
        puts "element not found"
      end
      wait delay if delay.positive?
      driver.switch_tab 1
    end

    def apply_target_behavior result, target_type
      if config.skip_target && !result.text.match?(config.target_patterns.first)
        log :"#{target_type}_target", "Пропуск неосновного сайта"
        return
      end
      n = determine_explore_deepness! result
      log :"#{target_type}_target", "глубина = #{n}"
      visit result, config.pre_delay_target
      return if n.zero?
      n.times do |i|
        start_time = Time.now.to_i
        wait 3
        print "  "
        scroll while (driver.scroll_height - 10) >= driver.y_offset
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
      n = config.explore_deepness
      return n if config.unique_visit_ip? == false || n.zero?
      if Ip.current == Storage.get(result.text[0, 20])
        log(:info, "Посещение с таким IP уже было. Глубина установлена на 0")
        return 0
      else
        Storage.set(result.text[0, 20], Ip.current)
        return n
      end
    end

    def apply_rival_behavior result
      scroll_percent = config.scroll_height_non_target
      log(:non_target, "прокрутка #{scroll_percent}%")

      if config.skip
        log :skip, "процент пропуска нецелевых"
        return
      end

      if config.unique_visit_ip?
        if Ip.current == Storage.get(result.text[0, 20])
          log(:info, "Посещение с таким IP уже было")
          return
        else
          Storage.set(result.text[0, 20], Ip.current)
        end
      end

      visit result, config.pre_delay_non_target
      return if scroll_percent.nil? || scroll_percent.zero?
      start_time = Time.now.to_i
      wait 3
      print "  "
      scroll while (driver.scroll_height * 0.01 * scroll_percent) >= driver.y_offset
      puts
      if config.min_visit_non_target + start_time > Time.now.to_i
        wait((config.min_visit_non_target + start_time) - Time.now.to_i)
      end
      # sleep rand(0.2..2)
    end

    def visit_some_link
      link = some_link
      return unless link
      log(:link, link.text)
      driver.scroll_to(link.location.y - rand(120..220))
      wait :avg
      link.click
    end

    def scroll
      sleep config.scroll_delay
      driver.scroll_by config.scroll_amount
      print "."
    end
  end
end
