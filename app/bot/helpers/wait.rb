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

      def wait time, options = {}
        interval = if time.is_a?(Symbol)
                     if options[:behavior]
                       behavior_config(time)
                     else
                       config.send(time) || INTERVALS.fetch(time, 0)
                     end
                   else
                     time
                   end
        return unless interval&.positive?

        log :wait, interval unless options[:skip_logs]
        sleep interval
      end

      def wait_until timeout = SMALL_WAIT, &block
        Selenium::WebDriver::Wait.new(timeout: timeout).until(&block)
      end
    end
  end
end
