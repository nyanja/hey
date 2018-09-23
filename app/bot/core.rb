# coding: utf-8
# frozen_string_literal: true

require "yaml"

module Bot
  class Core
    attr_reader :config, :driver

    include Helpers::Waiter
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
      connection_setup_exception_handler
      retry
    end

    def wait_for_connection
      Ip.ping
    rescue HTTP::ConnectionError
      connection_setup_exception_handler
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
      thr.kill
    rescue HTTP::ConnectionError
      connection_lost_exception_handler(thr)
      # raise StandardError
    rescue StandardError => e
      standart_exception_handler(thr, e)
    end

    def wait_for_new_ip
      while Ip.same? && config.unique_query_ip?
        log(:info, "Ожидание смены IP", Ip.current)
        configured_wait(:check_ip_delay)
      end
    rescue HTTP::ConnectionError
      connection_setup_exception_handler
      retry
    end
  end
end
