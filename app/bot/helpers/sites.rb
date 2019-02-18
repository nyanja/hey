# frozen_string_literal: true

module Bot
  module Helpers
    module Sites
      def search
        check_query_options
        driver.navigate.to("https://yandex.ru")
        search_bar = wait_until { driver.find_element(name: "text") }
        driver.type search_bar, @query
        wait(:min)
        search_bar.submit
        wait(:min)
      end

      def some_link
        driver.find_element(class: config.nav_classes.sample)
              .find_elements(tag_name: :a).sample
      end

      def check_query_options
        match = query.match(/(.+) ~ ?(.+)/)
        return unless match

        @query = match[1]
        match[2].scan(/(?=-?)\w+/).each { |k| @query_options[k.to_sym] = true }
      end
    end
  end
end
