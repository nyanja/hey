# frozen_string_literal: true

module Bot
  class Core
    attr_accessor :config, :driver
    attr_reader :query

    include Helpers::Wait
    include Helpers::Logger
    include Helpers::ExceptionHandler
    include Scenarios

    def initialize path_to_config
      @config = Helpers::Config.new(path_to_config)
    end

    def execute
      Thread.abort_on_exception = true
      loop do
        config.queries.each do |query|
          refresh_ip
          wait_for_connection
          prepare_for_scenario query
        rescue Interrupt
          puts "\nВыход..."
          exit
        rescue StandardError => _e
          sleep 5
          next
        end
      end
    end

    private

    def refresh_ip
      log(:ip, Ip.refresh!)
    rescue Typhoeus::Errors::TyphoeusError
      handle_no_connection
      retry
    end

    def wait_for_connection
      Ip.ping
    rescue Typhoeus::Errors::TyphoeusError
      handle_no_connection
      retry
    end

    def prepare_for_scenario query
      @query = query
      @driver = Driver.new self
      initialize_ip_check_thread

      launch_mode
    rescue Typhoeus::Errors::TyphoeusError
      Storage.del "refresh_ip"
      handle_disconnect
    rescue StandardError => e
      handle_exception e
    ensure
      @thread&.kill
    end

    def initialize_ip_check_thread
      @thread = Thread.new do
        loop do
          Ip.ping
          sleep 4
        end
      end
    end

    def launch_mode
      return manual_mode if config.mode == 3

      log(:query, @query, "[#{driver.device}]")
      config.mode == 2 ? lite_scenario : select_scenario
    end

    def manual_mode
      loop do
        break unless @driver.window_handles.count >= 1

        sleep 1
      end
      raise Interrupt # no need in custom error... for now...
    end

    def core
      self
    end
  end
end
