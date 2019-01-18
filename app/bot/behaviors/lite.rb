# frozen_string_literal: true

module Bot
  module Behaviors
    class Lite
      def perform index
        unless status
          log :skip, domain(@result)
          next
        end
        log(:visit, "##{index + 1} #{domain(@result)}", "[#{driver&.device}]")
        visit
      end
    end
  end
end