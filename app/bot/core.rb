# frozen_string_literal: true

require "yaml"

module Bot
  class Core
    attr_reader :config

    def initialize path_to_config
      @config = ConfigObject.new(YAML.load_file(path_to_config))
    end

    def execute
      Thread.abort_on_exception = true
      loop do
        config.queries.each do |query|
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
      w = config.check_ip_delay
      Logger.wait w
      sleep w
      retry
    end

    def wait_for_connection
      Ip.ping
    rescue HTTP::ConnectionError
      Logger.error "Нет соединения. Ожидание подключения..."
      w = config.check_ip_delay
      Logger.wait w
      sleep w
      retry
    end

    def perform_scenario query
      drv = Driver.new config
      scn = Scenario.new drv, config, query
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
        drv.close
        drv.close_all_tabs
        thr.kill
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
      # sleep config.error_delay || 10
      sleep 1
    end

    def wait_for_new_ip
      while Ip.same? && config.unique_query_ip?
        Logger.info "Ожидание смены IP", Ip.current
        Logger.wait config.check_ip_delay
        sleep config.check_ip_delay
      end
    rescue HTTP::ConnectionError
      Logger.error "Нет соединения. Ожидание подключения..."
      w = config.check_ip_delay
      Logger.wait w
      sleep w
      retry
    end
  end

  class ConfigObject
    def initialize cfg
      @cfg = cfg
    end

    def respond_to_missing?
      true
    end

    def method_missing method, *_args
      if @cfg.key? method.to_s
        @cfg[method.to_s]

      elsif @cfg.key? "#{method}_range"
        rand Range.new(*@cfg["#{method}_range"])

      elsif @cfg.key? "#{method}_patterns"
        Regexp.new(@cfg["#{method}_patterns"].join("|"), "i")

      elsif @cfg.key? "#{method}_sample"
        @cfg["#{method}_sample"].sample

      elsif @cfg.key? "#{method}_chance"
        @cfg["#{method}_chance"] > rand(0..100)
      end
    end
  end
end
