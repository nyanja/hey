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

    def initialize core, query
      @core = core
      @query = query

      @verified_results = []
      @pseudo = config.pseudo_targets.dup
      @last_target = nil
      @target_presence = nil
      @actual_index = 0
    end

    def default
      return if delayed_query? && config.unique_query_ip?
      search
      wait(:min)
      exit_code = handle_results
      driver.quit
      wait(:query_delay)
      exit_code
    rescue Selenium::WebDriver::Error::NoSuchElementError => e
      log(:error, "Нетипичная страница поиска")
      puts e.inspect
      driver.quit
    end

    def delayed_query?
      ts = Storage.get(query).to_i
      return false unless ts
      time = ((Time.now - Time.at(ts)) / 60).round
      if time > config.query_skip_interval
        Storage.del query
        return false
      end
      driver.close
      log(:skip!, "Запрос отложен. Осталось " \
                  "#{config.query_skip_interval - time} мин.")
      wait(:query_delay)
      true
    end

    def search
      yandex_search
    end

    def handle_results
      yandex_search_results.each_with_index do |result, i|
        break if i > config.results_count.to_i && @pseudo.empty? &&
                 @target_presence

        next if skip_result?(result)

        begin
          # ignore yandex turbo pages
          result.find_element(class: "overlay_js_intend")
          next
        rescue Selenium::WebDriver::Error::NoSuchElementError
          nil
        end

        @actual_index += 1
        status = nil
        info = @actual_index

        if result.text.match?(config.target)
          @target_presence = @actual_index
          @last_target = @actual_index
          status = :main
        elsif @pseudo.first && @target_presence &&
              @pseudo.first == @actual_index - @last_target
          @pseudo.shift
          @last_target = @actual_index
          status = :pseudo
        elsif @actual_index > config.results_count
          status = :skip
        end

        # TODO: Separate class for each result
        @verified_results << [result, status, info]
      end

      if !@target_presence && config.query_skip_on_presence?
        log(:skip!, "Продвигаемого сайта нет на странице")
        defer_query
      elsif @target_presence && @target_presence <= config.query_skip_on_position
        log(:skip!, "Продвигаемый сайт уже на высокой позиции")
        defer_query
      else
        @verified_results.each { |r| parse_result(*r) }
        :pass
      end
    end

    def skip_result? result
      return unless result.text.match?(config.ignore)
      log(:skip, result.text)
      true
    end

    def defer_query
      log(:info, "Запрос отложен на #{config.query_skip_interval} мин.")
      Storage.set query, Time.now.to_i
    end

    def parse_result result, status, info
      log(:visit, "##{info} #{result.text}")

      if config.skip && !status
        log(:skip, "Игнорирование ссылки")
      elsif status == :skip
        log(:skip, "Лимит обрабатываемых результатов превышен")
      else
        parse_result_page(result, status)
      end

      wait(:result_delay)
    rescue Selenium::WebDriver::Error::StaleElementReferenceError
      log :error, "Страница неактуальна"
      wait 4
    end

    def parse_result_page result, status
      if status
        apply_good_behavior result, status
      else
        apply_bad_behavior result
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
      if e.class == HTTP::ConnectionError
        raise e.class
      end
      puts
      log :error, "Ошибка на странице результата", e.inspect
    ensure
      driver.close_tab
    end

    def visit result
      driver.scroll_to [(result.location.y - rand(140..300)), 0].max
      sleep 1
      begin
        click({ class: "organic__url" }, result)
      rescue Selenium::WebDriver::Error::NoSuchElementError
        click({ class: "organic__link" }, result)
      rescue Selenium::WebDriver::Error::NoSuchElementError
        puts "link not found"
      end
      driver.switch_tab 1
    end

    def apply_good_behavior result, target_type
      n = determine_explore_deepness! target_type
      log :"#{target_type}_target", "глубина = #{n}"
      visit result
      wait :pre_delay_target
      return if n.zero?
      n.times do |i|
        wait 3
        print "  "
        scroll while (driver.scroll_height - 10) >= driver.y_offset
        puts
        if n != i.succ
          wait(:explore_delay)
          visit_some_link
        end
      rescue Selenium::WebDriver::Error::NoSuchElementError
        log(:error, "Нет подходящей ссылки для перехода")
      end
    end

    def determine_explore_deepness! target_type
      n = config.explore_deepness
      return n if config.unique_visit_ip? == false || n.zero?
      if Ip.same?
        log(:info, "Посещение с таким IP уже было. Глубина установлена на 0")
        return 0
      else
        log(:info, "IP изменился. Посещение разрешено")
        # Ip.refresh!
        Storage.set "refresh_ip", true if target_type == :main
        return n
      end
    end

    def apply_bad_behavior result
      scroll_percent = config.scroll_height_non_target
      log(:non_target, "прокрутка #{scroll_percent}%")
      visit result
      wait :pre_delay_non_target
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
