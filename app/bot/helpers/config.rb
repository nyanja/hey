# frozen_string_literal: true

require "yaml"

module Bot
  module Helpers
    class Config
      include Wait

      attr_reader :config

      VALUES = %w[range patterns sample chance].freeze
      DEFAULTS = { query_skip_on_position: 0,
                   result_delay: 2,
                   check_ip_delay: BIG_WAIT,
                   query_delay: MEDIUM_WAIT,
                   "unique_visit_ip?": false,
                   pseudo_targets: [],
                   throttling_latency: 0,
                   throttling_trhoughput: 500,
                   scroll_speed: 4,
                   results_limit: 100 }.freeze

      def initialize path_to_config
        @config = YAML.load_file(path_to_config)
      end

      def respond_to_missing?
        true
      end

      def method_missing method, *_args
        method = method.to_s
        return @config[method] if @config.key?(method)
        key = VALUES.select { |value| @config.key?("#{method}_#{value}") }.first
        return DEFAULTS[method.to_sym] unless key
        send("#{key}_value", method)
      end

      def range_value method
        rand Range.new(*@config["#{method}_range"])
      end

      def patterns_value method
        p = @config["#{method}_patterns"]
        return nil unless p
        Regexp.new(p.join("|"), "i")
      end

      def sample_value method
        @config["#{method}_sample"].sample
      end

      def chance_value method
        @config["#{method}_chance"] > rand(0..100)
      end

      def scroll_speed target = nil
        target ? scroll_speed_target : @config["scroll_speed"]
      end
    end
  end
end
