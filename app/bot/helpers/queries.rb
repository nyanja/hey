module Bot
  module Helpers
    module Queries
      def count_this_query
        Storage.incr("qc//#{query}")
      end

      def query_limited?
        c = config.query_skip_on_limit
        return if c.nil? || c.zero? || Storage.get("qc//#{query}").to_i <= c
        Storage.set("delay//#{query}",
                    Time.now.to_i + config.query_skip_on_limit_interval)
      end
    end
  end
end
