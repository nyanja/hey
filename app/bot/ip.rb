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

      def debug
        puts current
        puts fetch_ip
      end

      private

      def fetch_ip
        HTTP.get("http://canhazip.com").to_s
      end
    end
  end
end
