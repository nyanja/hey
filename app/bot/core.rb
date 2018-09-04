# frozen_string_literal: true

module Bot
  class Core
    attr_reader :config

    def initialize config
      @config = ConfigObject.new(config)
    end

    def execute
      config.queries.each do |query|
        drv = Driver.new config
        scn = Scenario.new drv, config
        scn.default query
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
      @cfg.fetch(method.to_s, nil)
    end
  end
end
