# frozen_string_literal: true

module Bot
  module Behaviors
    class Lite < Base
      def perform index
        if !@visit_type || @visit_type == :skip
          log :skip, domain(@result)
          return
        end
        log(:visit, "##{index + 1} #{domain(@result)}", "[#{driver&.device}]")
        visit
      end

      # needed?
      # def visit_wait
      # wait config.lite_pre_delay
      # end
    end
  end
end
