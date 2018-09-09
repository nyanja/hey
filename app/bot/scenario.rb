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
      inspect_results
      sleep 4
      clean_up
    end

    def search query
      drv.navigate.to "https://#{cfg.engine}" # yandex only
      wait :min
      bar = drv.find_element(id: "text") # mocked
      drv.type bar, query
      wait :min
      bar.submit
      wait :page_loading
    end

    def inspect_results
      content = drv.find_element class: "content__left"
      results = content.find_elements class: "serp-item", tag_name: "li"
      drv.scroll_to rand(0..600)
      wait :min
      verified_results = []

      while verified_results.count < cfg.results_count.to_i
        result = results.shift
        next if result.text.match?(/#{cfg.ignore.join("|")}/i)
        verified_results << result
      end

      verified_results.each { |r| handle_result r }
    end

    def clean_up
      drv.close_all_tabs
    end

    def handle_result result
      text = result.text

      drv.scroll_to [(result.location.y - rand(140..300)), 0].max
      wait :min
      result.find_element(class: "organic__url").click
      wait :min
      drv.switch_tab 1

      if cfg.target && text.match?(/#{cfg.target.join"|"}/i)
        apply_good_behavior
      else
        apply_bad_behavior
      end

      drv.close
      drv.switch_tab 0
      sleep cfg.query_delay

    rescue Selenium::WebDriver::Error::StaleElementReferenceError
      drv.close
      drv.switch_tab 0
    rescue StandardError => e
      puts e.inspect
      puts e.backtrace
      sleep 4
    end

    def apply_good_behavior
      n = cfg.explore_deepness.succ
      n.times do |i|
        scroll while (drv.scroll_height - 10) >= drv.y_offset
        wait :avg
        visit_some_link if n != i
      end
    end

    def apply_bad_behavior
      scroll_percent = cfg.scroll_height_non_target
      return if scroll_percent.nil? || scroll_percent.zero?
      scroll while (drv.scroll_height * 0.01 * scroll_percent) >= drv.y_offset
      sleep rand(0.2..2)
    end

    def visit_some_link
      nav = drv.find_element(class: cfg.nav_classes.sample)
      return unless nav
      link = nav.find_elements(tag_name: :a).sample
      return unless link
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
