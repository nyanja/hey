# frozen_string_literal: true

module Bot
  module Helpers
    module Waiter
      SMALLEST_WAIT = 2
      SMALL_WAIT = 4
      MEDIUM_WAIT = 30
      BIG_WAIT = 100

      INTERVALS = { page_loading: 5,
                    min: 2,
                    avg: 3 }.freeze

      def configured_wait time
        time = config.send(time) if time.is_a?(Symbol)
        log(:wait, time)
        sleep time
      end

      def wait time
        time = INTERVALS.fetch(time, 0) if time.is_a?(Symbol)
        sleep time
      end

      def selenium_wait timeout = SMALL_WAIT
        Selenium::WebDriver::Wait.new(timeout: timeout)
      end
    end
  end
end
