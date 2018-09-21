# frozen_string_literal: true

require "http"

module Bot
  module Ip
    class << self
      attr_reader :current

      def refresh!
        @current = fetch_ip
      end

      def same?
        current == fetch_ip
      end

      def differ?
        current != fetch_ip
      end

      def ping
        fetch_ip
      end

      private

      def fetch_ip
        HTTP.get("http://canhazip.com").to_s
        # YAML.load_file("./config_example.yml")["test_ip"]
      end
    end
  end
end
