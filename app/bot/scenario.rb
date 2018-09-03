# frozen_string_literal: true

module Bot
  class Scenario
    attr_reader :drv, :cfg

    def initialize driver, config
      @drv = driver
      @cfg = config
    end

    def default
      search
      inspect_results
    end

    def search
      drv.navigate.to "https://#{cfg.engine}" # yandex only
      wait :min
      bar = drv.find_element(id: "text") # mocked
      drv.type bar, cfg.query
      wait :min
      bar.submit
      wait :page_loading
    end

    def inspect_results
      content = drv.find_element class: "content__left"
      results = content.find_elements class: "serp-item", tag_name: "li"
      drv.scroll_to rand(0..600)
      wait :min
      results.take(6).each { |r| handle_result r }
    end

    def handle_result result
      text = result.text
      return if text.match?(/#{cfg.ignore.join("|")}/i)

      drv.scroll_to [(result.location.y - rand(140..300)), 0].max
      wait :min
      result.find_element(class: "organic__url").click
      wait :page_loading
      drv.switch_tab 1

      if cfg.target && text.match?(/#{cfg.target}/)
        apply_good_behavior
      else
        apply_bad_behavior
      end

      drv.switch_tab 0
      wait :avg
    rescue
    end

    def apply_good_behavior
      n = rand(1..3)
      n = 2
      n.times do
        wait :page_loading
        scroll while (drv.scroll_height + 10) >= drv.y_offset
        wait :avg
        visit_some_link if n != 1
      end
    end

    def apply_bad_behavior
      rand(2..7).times do
        scroll
      end
      sleep rand(0.2..2)
    end

    def visit_some_link
      el = drv.find_element class: cfg.nav_classes.sample
      link = el.find_elements(tag_name: :a).sample
      drv.scroll_to link.location.y - rand(120..220)
      wait :avg
      link.click
    end

    def scroll
      sleep rand(0.4..2.4)
      drv.scroll_by rand(40..180)
    end

    def wait key
      intervals = { page_loading: 5,
                    min: 0.4,
                    avg: 1 }
      sleep intervals.fetch(key, 0)
    end
  end
end
