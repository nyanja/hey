# frozen_string_literal: true

module Bot
  module Helpers
    module Sites
      def search
        driver.navigate.to("https://yandex.ru")
        # wait(:min)
        # search_bar = driver.find_element(id: "text")
        search_bar = wait_until { driver.find_element(name: "text") }
        driver.type search_bar, query
        wait(:min)
        search_bar.submit
        wait(:min)
      end

      def search_results
        driver.find_element(class: "serp-list")
              .find_elements(class: "serp-item")
      end

      def some_link
        driver.find_element(class: config.nav_classes.sample)
              .find_elements(tag_name: :a).sample
      end
    end
  end
end
