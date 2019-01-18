# frozen_string_literal: true

# requires core and query methods to be available
module Bot
  module Scenarios
    def select_scenario
      case query
      when %r{^https?:\/\/}
        Behaviors.perform_single_visit(core, link)
        wait(:query_delay)
        return
      when %r{\/}
        right_clicks_scenario
        wait(:query_delay)
        return
      end

      return if query_delayed? ||
                query_limited?

      default_scenario
    end

    def lite_scenario
      Lite.new(core, query)
    end

    def right_clicks_scenario
      RightClick.new(core, query)
    end

    def default_scenario
      Default.new(core, query)
    end
  end
end
