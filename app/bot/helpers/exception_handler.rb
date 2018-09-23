# coding: utf-8
# frozen_string_literal: true

module Bot
  module Helpers
    module ExceptionHandler
      # Core ip fetching iterations
      def connection_setup_exception_handler
        log(:error, "Нет соединения. Ожидание подключения...")
        configured_wait(:check_ip_delay)
        # retry after each `connection_setup_exception_handler` call
      end

      # Core.perform scenario
      def connection_lost_exception_handler thread
        log(:error, "Потеря соединения")
        begin
          thread.kill
          # driver.close
          # driver.close_all_tabs
          driver.quit
        rescue StandardError => e
          puts e.message
          # nil
        end
      end

      # Core.perform_scenario
      def standart_exception_handler thread, error
        puts error.inspect
        puts error.backtrace
        thread.kill
        begin
          # driver.close
          # driver.close
          driver.quit
        rescue StandardError
          nil
        end
        # sleep config.error_delay || 10
        sleep 1
      end
    end
  end
end
