# frozen_string_literal: true

module Bot
  class Scenario
    attr_reader :drv, :cfg, :query

    def initialize driver, config, query
      @drv = driver
      @cfg = config
      @query = query
    end

    def default
      return if delayed_query? && cfg.unique_query_ip?
      search
      wait :min
      exit_code = handle_results
      clean_up
      sleep cfg.query_delay
      exit_code
    end

    def search
      drv.navigate.to "https://yandex.ru" # yandex only
      wait :min
      bar = drv.find_element(id: "text") # mocked
      drv.type bar, query
      wait :min
      bar.submit
      # wait :page_loading
    end

    def handle_results
      content = drv.find_element class: "content__left"
      results = content.find_elements class: "serp-item", tag_name: "li"
      verified_results = []
      pseudo = cfg.pseudo_targets || []
      last_target = nil
      target_presence = nil
      actual_index = 0

      results.each_with_index do |result, i|
        break if i > cfg.results_count.to_i && pseudo.empty?
        if result.text.match?(cfg.ignore)
          Logger.skip result.text
          last_target += 1 if last_target
          next
        end

        actual_index += 1
        is_target = nil

        if result.text.match?(cfg.target)
          target_presence = actual_index
          last_target = actual_index
          is_target = :main
        elsif pseudo.first && target_presence && pseudo.first == actual_index - last_target
          pseudo.shift
          last_target = actual_index
          is_target = :pseudo
        end

        verified_results << [result, is_target]
      end

      if !target_presence && cfg.query_skip_on_presence?
        Logger.skip! "Продвигаемого сайта нет на странице"
        Logger.info "Запрос отложен на #{cfg.query_skip_interval} мин."
        Storage.set query, Time.now.to_i
      elsif target_presence <= (cfg.query_skip_on_position || 0)
        Logger.skip! "Продвигаемый сайт уже на высокой позиции"
        Logger.info "Запрос отложен на #{cfg.query_skip_interval} мин."
        Storage.set query, Time.now.to_i
      else
        verified_results.each { |r| handle_result(*r) }
        :pass
      end

    rescue Selenium::WebDriver::Error::NoSuchElementError => e
      Logger.error "Нетипичная страница поиска"
      # puts e.message
      # puts e.backtrace
    end

    def clean_up
      drv.close_all_tabs
    end

    def delayed_query?
      ts = Storage.get(query).to_i
      return unless ts
      time = ((Time.now - Time.at(ts)) / 60).round
      if time > cfg.query_skip_interval
        Storage.del query
        return
      end
      clean_up
      Logger.skip! "Запрос отложен. Осталось #{cfg.query_skip_interval - time} мин."
      w = cfg.query_delay
      Logger.wait w
      sleep w
      true
    end

    def handle_result result, is_target = nil
      text = result.text
      Logger.visit text

      if cfg.skip && !is_target
        Logger.skip "игнорирование ссылки"
      else
        drv.scroll_to [(result.location.y - rand(140..300)), 0].max
        wait :min
        result.find_element(class: "organic__url").click
        sleep 0.2
        drv.switch_tab 1

        if is_target
          apply_good_behavior is_target
        else
          apply_bad_behavior
        end

        drv.close
        drv.switch_tab 0
      end

      sleep cfg.result_delay || 2
    rescue Selenium::WebDriver::Error::StaleElementReferenceError
      drv&.close
      drv&.switch_tab 0
      Logger.error "Страница неактуальна"
      sleep 4
    rescue Net::ReadTimeout
      drv&.close
      drv&.switch_tab 0
      Logger.error "Необрабатываемая страница"
      sleep 4
    end

    def apply_good_behavior target_type
      n = cfg.explore_deepness
      Logger.send "#{target_type}_target", "глубина = #{n}"
      n.times do |i|
        scroll while (drv.scroll_height - 10) >= drv.y_offset
        w = cfg.explore_delay
        Logger.wait w
        sleep w
        visit_some_link if n != i.succ
      rescue Selenium::WebDriver::Error::NoSuchElementError
        Logger.error "Нет подходящей ссылки для перехода"
        break
      end
    end

    def apply_bad_behavior
      scroll_percent = cfg.scroll_height_non_target
      Logger.non_target "прокрутка #{scroll_percent}%"
      return if scroll_percent.nil? || scroll_percent.zero?
      scroll while (drv.scroll_height * 0.01 * scroll_percent) >= drv.y_offset
      sleep rand(0.2..2)
    end

    def visit_some_link
      nav = drv.find_element(class: cfg.nav_classes.sample)
      link = nav.find_elements(tag_name: :a).sample
      return unless link
      Logger.link link.text
      drv.scroll_to(link.location.y - rand(120..220))
      wait :avg
      link.click
    end

    def scroll
      sleep cfg.scroll_delay
      drv.scroll_by cfg.scroll_amount
    end

    def wait key
      intervals = { page_loading: 5,
                    min: 2,
                    avg: 3 }
      sleep intervals.fetch(key, 0)
    end
  end
end
