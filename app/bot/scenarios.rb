# frozen_string_literal: true

module Bot
  module Scenarios
    def custom query
      case query
      when %r{^https?:\/\/}
        single query
        wait(:query_delay)
        return
      when %r{\/}
        right_clicks query
        wait(:query_delay)
        return
      end

      return if query_delayed? ||
                query_limited?

      default
    end

    # using query_delayed?, search, parse_results, search_results,
    # +lite_process_query, +visit
    def lite query
      Lite.new(query)
    end

    # using: search, search_results, Scenarios.single, wait
    def right_clicks query
      RightClick.new(driver, query)
    end

    # using: search, parse_results, process_query
    def default query
      Default.new(driver, query)
    end

    # should separate it from base? It looks very independent.
    # And called inside scenarios
    def single link
      Single.new(driver, link)
    end
  end
end
