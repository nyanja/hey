# frozen_string_literal: true

module Bot
  module Scenarios
    class Lite < Base
      def perform
        return if query_delayed?

        search
        parse_results && process_results
        driver.quit
        wait(:query_delay)
      rescue Selenium::WebDriver::Error::NoSuchElementError => e
        log(:error, "Нетипичная страница поиска")
        puts e.inspect
        driver.quit
      end
    end

    def process_results
      @verified_results.each do |result, status, info|
        apply_lite_behavior(result, status, info)
      ensure
        driver&.close_tab
      end
    end
  end
end
