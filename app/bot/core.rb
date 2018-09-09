# frozen_string_literal: true

module Bot
  class Core
    attr_reader :config

    def initialize config
      @config = ConfigObject.new(config)
    end

    def execute
      config.queries.each do |query|
        begin
          drv = Driver.new config
          scn = Scenario.new drv, config
          scn.default query
        rescue Net::ReadTimeout
          drv&.close
          sleep 20
          next
        end
      end
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
      end
    end
  end
end
