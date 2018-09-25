# frozen_string_literal: true

module Bot
  module Helpers
    module Wait
      include Logger

      SMALLEST_WAIT = 2
      SMALL_WAIT = 4
      MEDIUM_WAIT = 30
      BIG_WAIT = 100

      INTERVALS = { page_loading: 5,
                    min: 1,
                    avg: 3 }.freeze

      def wait time
        interval = if time.is_a?(Symbol)
                     config.send(time) || INTERVALS.fetch(time, 0)
                   else
                     time
                   end
        return if interval.zero?
        log :wait, interval
        sleep interval
      end

      def wait_until timeout = SMALL_WAIT, &block
        Selenium::WebDriver::Wait.new(timeout: timeout).until(&block)
      end
    end
  end
end
