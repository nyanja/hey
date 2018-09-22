# frozen_string_literal: true

module Bot
  module Helpers
    module Sites
      def yandex_search
        driver.navigate.to("https://yandex.ru")
        # wait(:min)
        # search_bar = driver.find_element(id: "text")
        search_bar = selenium_wait { driver.find_element(id: "text") }
        driver.type search_bar, query
        wait(:min)
        search_bar.submit
      end

      def yandex_search_results
        driver.find_element(class: "content__left")
              .find_elements(class: "serp-item", tag_name: "li")
      end

      def some_link
        driver.find_element(class: config.nav_classes.sample)
              .find_elements(tag_name: :a).sample
      end
    end
  end
end
