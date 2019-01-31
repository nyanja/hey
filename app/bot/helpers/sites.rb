# frozen_string_literal: true

module Bot
  module Helpers
    module Sites
      def search search_text = query
        driver.navigate.to("https://yandex.ru")
        # wait(:min)
        # search_bar = driver.find_element(id: "text")
        search_bar = wait_until { driver.find_element(name: "text") }
        driver.type search_bar, search_text
        wait(:min)
        search_bar.submit
        wait(:min)
      end

      def some_link
        driver.find_element(class: config.nav_classes.sample)
              .find_elements(tag_name: :a).sample
      end
    end
  end
end
