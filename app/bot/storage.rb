# frozen_string_literal: true

require "redis"

module Bot
  module Storage
    class << self

      def method_missing key, *args, &block
        super unless db.respond_to? key
        db.send key, *args
      end

      private

      def db
        @db ||= Redis.new
      end
    end
  end
end
