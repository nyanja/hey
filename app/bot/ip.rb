# frozen_string_literal: true

# require "http"
require 'typhoeus'

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
        # `curl -s 'http://canhazip.com'`
        # Typhoeus.get("http://canhazip.com").body
        # HTTP.get("http://canhazip.com").to_s
        # YAML.load_file("./config_example.yml")["test_ip"]

        res = Typhoeus.get("http://canhazip.com", timeout: 3)
        unless res.success?
          raise Typhoeus::Errors::TyphoeusError
        end
        res.body
      end
    end
  end
end
