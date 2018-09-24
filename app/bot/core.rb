# frozen_string_literal: true

require "yaml"

module Bot
  class Core
    attr_reader :config, :driver

    include Helpers::Wait
    include Helpers::ExceptionHandler
    include Helpers::Logger

    def initialize path_to_config
      @config = Helpers::Config.new(YAML.load_file(path_to_config))
    end

    def execute
      Thread.abort_on_exception = true
      loop do
        config.queries.each do |query|
          wait_for_connection

          log(:query, query)

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
      log(:ip, Ip.refresh!)
    rescue HTTP::ConnectionError
      handle_no_connection
      retry
    end

    def wait_for_connection
      Ip.ping
    rescue HTTP::ConnectionError
      handle_no_connection
      retry
    end

    def perform_scenario query
      @driver = Driver.new self
      scn = Scenario.new self, query
      thr = Thread.new do
        loop do
          Ip.ping
          sleep 10
        end
      end
      scn.default
    rescue HTTP::ConnectionError
      handle_disconnect
    rescue StandardError => e
      handle_exception e
    ensure
      thr&.kill
    end

    def wait_for_new_ip
      while Ip.same? && config.unique_query_ip?
        log(:info, "Ожидание смены IP", Ip.current)
        wait(:check_ip_delay)
      end
    rescue HTTP::ConnectionError
      handle_no_connection
      retry
    end
  end
end
