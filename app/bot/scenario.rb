# coding: utf-8
# frozen_string_literal: true

module Bot
  class Scenario
    attr_reader :core, :query

    extend Forwardable
    def_delegators :core, :driver, :config
    def_delegators :driver, :close_active_tab, :clean_up, :click

    include Helpers::Logger
    include Helpers::Waiter

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
      clean_up
      configured_wait(:query_delay)
      exit_code
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
      configured_wait(:query_delay)
      true
    end

    def search
      yandex_search
    rescue Selenium::WebDriver::Error::NoSuchElementError
      log(:error, "Нетипичная страница поиска")
      driver&.close
    end

    def handle_results
      yandex_search_results.each_with_index do |result, i|
        break if i > config.results_count.to_i && pseudo.empty? &&
                 target_presence

        next if skip_result?(result)

        @actual_index += 1
        status = nil
        # used only actual_index?
        info = [@last_target, @actual_index, @pseudo.first]

        if result.text.match?(config.target)
          @target_presence = @actual_index
          @last_target = @actual_index
          status = :main
        elsif @pseudo.first && @target_presence &&
              @pseudo.first == @actual_index - @last_target
          @pseudo.shift
          @last_target = @actual_index
          status = :pseudo
        elsif actual_index > config.results_count
          status = :skip
        end

        # TODO: Separate class for each result
        @verified_results << [result, status, info]
      end

      handle_result(query)
    rescue Selenium::WebDriver::Error::NoSuchElementError
      log(:error, "Нетипичная страница")
      close_active_tab
    end

    def skip_result? result
      return unless result.text.match?(config.ignore)
      log(:skip, result.text)
    end

    def handle_result query
      if !@target_presence && config.query_skip_on_presence?
        log(:skip!, "Продвигаемого сайта нет на странице")
        defer_query query
      elsif @target_presence && @target_presence <=
                                config.query_skip_on_position
        log(:skip!, "Продвигаемый сайт уже на высокой позиции")
        defer_query query
      else
        @verified_results.each { |r| parse_result(*r) }
        :pass
      end
    end

    def defer_query query
      log(:info, "Запрос отложен на #{config.query_skip_interval} мин.")
      Storage.set query, Time.now.to_i
    end

    def parse_result result, status = nil, info = []
      log(:visit, "##{info[1]} #{result.text}")

      if config.skip && !status
        log(:skip, "Игнорирование ссылки")
      elsif status == :skip
        log(:skip, "Лимит обрабатываемых результатов превышен")
      else
        parse_result_page(result, status)
      end

      configured_wait(:result_delay)
    rescue Selenium::WebDriver::Error::StaleElementReferenceError
      close_active_tab(:error, "Страница неактуальна")
      wait(4)
    rescue Net::ReadTimeout
      close_active_tab(:error, "Необрабатываемая страница")
      wait(4)
    end

    def parse_result_page result, status
      driver.scroll_to [(result.location.y - rand(140..300)), 0].max
      wait :min
      click({ class: "organic__url" }, result)
      sleep 0.2
      driver.switch_tab 1

      if status
        apply_good_behavior status
      else
        apply_bad_behavior
      end

      close_active_tab
    end

    def apply_good_behavior target_type
      n = determine_explore_deepness! target_type
      log(:send, "#{target_type}_target", "глубина = #{n}")
      n.times do |i|
        scroll while (driver.scroll_height - 10) >= driver.y_offset
        configured_wait(:explore_delay)
        visit_some_link if n != i.succ
      rescue Selenium::WebDriver::Error::NoSuchElementError
        log(:error, "Нет подходящей ссылки для перехода")
        break
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

    def apply_bad_behavior
      scroll_percent = config.scroll_height_non_target
      log(:non_target, "прокрутка #{scroll_percent}%")
      return if scroll_percent.nil? || scroll_percent.zero?
      scroll while (driver.scroll_height * 0.01 * scroll_percent) >= driver.y_offset
      sleep rand(0.2..2)
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
    end
  end
end
