# frozen_string_literal: true

require "yaml"

module Bot
  module Helpers
    class Config
      include Wait

      attr_reader :config

      VALUES = %w[range patterns sample chance].freeze
      BEHAVIORS = /search|rival|target|link/.freeze

      # all defaults will be transformed in initialize
      DEFAULTS = { query_skip_on_position: 0,
                   result_delay: 2,
                   check_ip_delay: BIG_WAIT,
                   query_delay: MEDIUM_WAIT,
                   defered_query_delay: MEDIUM_WAIT,
                   open_timeout: 30,
                   read_timeout: 30,
                   page_load_timeout: 30,
                   "unique_visit_ip?": false,
                   pseudo_targets: [],
                   throttling_latency: 0,
                   throttling_trhoughput: 500,
                   scroll_height: 0,
                   scroll_speed: 4,
                   scroll_delay: 1,
                   results_limit: 100,
                   random_moving_iterations_range: [5, 10],
                   random_move_by_x_range: [-5, 5],
                   random_move_by_y_range: [-5, 5],
                   mouse_move_range: [3, 5],
                   mouse_move_delay_range: [0.008, 0.012] }.freeze

      def initialize path_to_config
        @config = DEFAULTS.transform_keys { |k| "default_#{k}" }
                          .merge(load_config(path_to_config))
      end

      private

      def load_config path_to_config
        YAML.load_file(path_to_config)
      end

      def respond_to_missing?
        false
      end

      def method_missing method, *_args
        method = method.to_s
        return behavior_value(method) if method.match?(BEHAVIORS)

        fetch_value(method)
      end

      def behavior_value method
        fetch_value(method) ||
          (method.match(/^pseudo_/) &&
           fetch_value(method.sub(/[^_]+/, "target"))) ||
          fetch_value(method.sub(/[^_]+_/, ""))
      end

      def fetch_value method, first = true
        return @config[method] if @config[method]

        key = VALUES.find { |v| @config.key?("#{method}_#{v}") }
        return send("#{key}_value", method) if key

        fetch_value("default_#{method}", nil) if first
      end

      def range_value method
        value = "#{method}_range"
        rand Range.new(*@config[value])
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
    end
  end
end
