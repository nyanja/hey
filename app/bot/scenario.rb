# frozen_string_literal: true

module Bot
  class Scenario
    attr_reader :drv, :cfg

    def initialize driver, config
      @drv = driver
      @cfg = config
    end

    def default query
      search query
      wait :min
      inspect_results
      clean_up
      sleep cfg.query_delay
    end

    def search query
      drv.navigate.to "https://yandex.ru" # yandex only
      wait :min
      bar = drv.find_element(id: "text") # mocked
      drv.type bar, query
      wait :min
      bar.submit
      # wait :page_loading
    end

    def inspect_results
      content = drv.find_element class: "content__left"
      results = content.find_elements class: "serp-item", tag_name: "li"
      verified_results = []
      pseudo = cfg.pseudo_targets || []
      last_target = 0
      target_presence = nil

      results.each_with_index do |result, i|
        break if i > cfg.results_count.to_i && pseudo.empty?
        if result.text.match?(cfg.ignore)
          Logger.skip result.text
          last_target += 1
          next
        end

        is_target = nil

        if result.text.match?(cfg.target)
          target_presence = true
          last_target = i
          is_target = :main
        elsif pseudo.first && pseudo.first == i - last_target
          pseudo.shift
          last_target = i
          is_target = :pseudo
        end

        verified_results << [result, is_target]
      end

      if !target_presence
        Logger.skip! "Продвигаемого сайта нет на странице"
      elsif verified_results.first.last
        Logger.skip! "Продвигаемый сайт уже на первом месте"
      else
        verified_results.each { |r| handle_result(*r) }
      end

    rescue Selenium::WebDriver::Error::NoSuchElementError => e
      Logger.error "Нетипичная страница поиска"
      # puts e.message
      # puts e.backtrace
    end

    def clean_up
      drv.close_all_tabs
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
