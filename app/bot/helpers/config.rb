# frozen_string_literal: true

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
                   pseudo_targets: [] }.freeze

      def initialize config
        @config = config
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
        Regexp.new(@config["#{method}_patterns"].join("|"), "i")
      end

      def sample_value method
        @config["#{method}_sample"].sample
      end

      def chance_value method
        @config["#{method}_chance"] > rand(0..100)
      end
    end
  end
end