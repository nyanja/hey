# frozen_string_literal: true

module Bot
  module Behaviors
    class Lite < Base
      def perform index
        unless @visit_type
          log :skip, domain(@result)
          return
        end
        log(:visit, "##{index + 1} #{domain(@result)}", "[#{driver&.device}]")
        visit
      end
    end
  end
end
