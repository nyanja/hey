# frozen_string_literal: true

module Bot
  module Scenarios
    class Lite < Base
      def perform
        return if query_delayed?

        search
        parse_results(search_results) && process_results
        driver.quit
        wait(:query_delay)
      rescue Selenium::WebDriver::Error::NoSuchElementError => e
        log(:error, "Нетипичная страница поиска")
        puts e.inspect
        driver.quit
      end
    end

    def process_results
      @verified_results.each do |(r, status, info)|
        unless status
          log :skip, domain(r)
          next
        end
        log(:visit, "##{info} #{domain(r)}", "[#{driver&.device}]")
        visit r
      ensure
        driver&.close_tab
        output_spent_time
      end
    end
  end
end
