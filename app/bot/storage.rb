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

      # May be some https://github.com/steveklabnik/request_store ?
      def db
        # it can cross with another ruby projects with default db
        @db ||= Redis.new(db: 11)
      end
    end
  end
end
