# frozen_string_literal: true

module Bot
  class Core
    attr_reader :config, :driver

    include Helpers::Wait
    include Helpers::ExceptionHandler
    include Helpers::Logger

    def initialize path_to_config
      @config = Helpers::Config.new(path_to_config)
    end

    def execute
      Thread.abort_on_exception = true
      loop do
        config.queries.each do |query|
          refresh_ip
          wait_for_connection
          perform_scenario query
        rescue Interrupt
          puts "\nВыход..."
          exit
        rescue StandardError
          sleep 5
          next
        end
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
      driver.network_conditions = {
        offline: false,
        latency: (config.throttling_latency || 0),
        throughput: 1024 * (config.throttling_trhoughput || 500)
      }
      log(:query, query, "[#{driver.device}]")
      scn = Scenario.new self, query
      thr = Thread.new do
        loop do
          Ip.ping
          sleep 10
        end
      end
      case config.mode
      when 2
        scn.lite
      else
        scn.default
      end
    rescue HTTP::ConnectionError
      Storage.del "refresh_ip"
      handle_disconnect
    rescue StandardError => e
      handle_exception e
    ensure
      thr&.kill
    end
  end
end
