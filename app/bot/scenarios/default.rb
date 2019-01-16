# frozen_string_literal: true

module Bot
  module Scenarios
    class Default < Base
      def perform
        search
        parse_results && process_query
        driver.quit
        wait(:query_delay)
      rescue Selenium::WebDriver::Error::NoSuchElementError => e
        log(:error, "Нетипичная страница поиска")
        puts e.inspect
        driver.quit
      end
    end

    def process_query
      count_this_query
      @verified_results.each { |r| parse_result(*r) }
      :pass
    end
  end
end
