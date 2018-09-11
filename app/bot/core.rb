# frozen_string_literal: true

require "yaml"

module Bot
  class Core
    attr_reader :config

    def initialize path_to_config
      @config = ConfigObject.new(YAML.load_file(path_to_config))
    end

    def execute
      config.queries.each_with_index do |query, i|
        drv = Driver.new config
        scn = Scenario.new drv, config
        scn.default query
        raise Retry if i.succ == config.queries.size
      rescue Retry
        # retry
      rescue RuntimeError
        drv&.close
        sleep 20
      end
    end
  end

  class Retry < StandardError
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
      end
    end
  end
end
