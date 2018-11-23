# frozen_string_literal: true

module Bot
  module Helpers
    module ExceptionHandler
      # Core ip fetching iterations
      def handle_no_connection
        # puts thread
        log(:error, "Нет соединения. Ожидание подключения...")
        raise Interrupt if config.mode == 3
        wait(:check_ip_delay)
        # retry after each `handle_no_connection` call
      end

      # Core.perform scenario
      def handle_disconnect
        log(:error, "Потеря соединения")
        driver&.quit
        raise Interrupt if config.mode == 3
      end

      # Core.perform_scenario
      def handle_exception error
        puts error.inspect
        puts error.backtrace
        driver&.quit
        # sleep config.error_delay || 10
        sleep 1
      end
    end
  end
end
