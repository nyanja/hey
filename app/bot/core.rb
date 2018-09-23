# frozen_string_literal: true

require "yaml"

module Bot
  class Core
    def self.run
      new.execute
    end

    def execute
      Thread.abort_on_exception = true
      loop do
        Config.queries.each do |query|
          wait_for_connection

          Logger.query query

          exit_code = perform_scenario query
          wait_for_new_ip if exit_code == :pass

          if Storage.get "refresh_ip"
            Storage.del "refresh_ip"
            refresh_ip
          end
        end

      rescue Interrupt
        puts "\nВыход..."
        exit
      end
    end

    private

    def refresh_ip
      Logger.ip Ip.refresh!
    rescue HTTP::ConnectionError
      Logger.error "Нет соединения. Ожидание подключения..."
      w = Config.check_ip_delay
      Logger.wait w
      sleep w
      retry
    end

    def wait_for_connection
      Ip.ping
    rescue HTTP::ConnectionError
      Logger.error "Нет соединения. Ожидание подключения..."
      w = Config.check_ip_delay
      Logger.wait w
      sleep w
      retry
    end

    def perform_scenario query
      drv = Driver.new
      scn = Scenario.new drv, query
      thr = Thread.new do
        loop do
          Ip.ping
          sleep 10
        end
      # rescue HTTP::ConnectionError
      #   Logger.error "Потеря соединения"
      #   begin
      #     drv.close
      #     drv.close
      #   rescue StandardError
      #     nil
      #   end
      end
      scn.default
      thr.kill

    rescue HTTP::ConnectionError
      Logger.error "Потеря соединения"
      begin
        thr.kill
        drv.close
        drv.close_all_tabs
      rescue StandardError => e
        puts e.message
        # nil
      end
      # raise StandardError
    rescue StandardError => e
      puts e.inspect
      thr.kill
      begin
        drv.close
        drv.close
      rescue StandardError
        nil
      end
      # sleep Config.error_delay || 10
      sleep 1
    end

    def wait_for_new_ip
      while Ip.same? && Config.unique_query_ip?
        Logger.info "Ожидание смены IP", Ip.current
        Logger.wait Config.check_ip_delay
        sleep Config.check_ip_delay
      end
    rescue HTTP::ConnectionError
      Logger.error "Нет соединения. Ожидание подключения..."
      w = Config.check_ip_delay
      Logger.wait w
      sleep w
      retry
    end
  end


end
