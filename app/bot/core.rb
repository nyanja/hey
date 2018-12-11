# frozen_string_literal: true

module Bot
  class Core
    attr_accessor :config, :driver

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
        rescue StandardError => e
          sleep 5
          next
        end
      end
    end

    private

    def refresh_ip
      log(:ip, Ip.refresh!)
    rescue Typhoeus::Errors::TyphoeusError # HTTP::ConnectionError
      handle_no_connection
      retry
    end

    def wait_for_connection
      Ip.ping
    rescue Typhoeus::Errors::TyphoeusError # HTTP::ConnectionError
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
      thr = Thread.new do
        loop do
          Ip.ping
          sleep 4
        end
      end
      case config.mode
      when 2
        log(:query, query, "[#{driver.device}]")
        run = Bot::Runner.new self, query
        run.lite_scenario
      when 3
        loop do
          break unless @driver.window_handles.count >= 1
          sleep 1
        end
      else
        log(:query, query, "[#{driver.device}]")
        run = Bot::Runner.new self, query
        run.default_scenario
      end
    rescue Typhoeus::Errors::TyphoeusError # HTTP::ConnectionError
      Storage.del "refresh_ip"
      handle_disconnect
    rescue StandardError => e
      handle_exception e
    ensure
      thr&.kill
    end
  end
end
