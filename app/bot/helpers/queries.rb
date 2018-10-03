module Bot
  module Helpers
    module Queries
      def count_this_query
        Bot::Storage.incr("qc//#{query}")
      end

      def query_limited?
        c = config.query_skip_on_limit
        return if c.nil? || c.zero? || Bot::Storage.get("qc//#{query}").to_i < c
        Bot::Storage.set("delay//#{query}",
                         Time.now.to_i +
                           config.query_skip_on_limit_interval * 60)
        Bot::Storage.del("qc//#{query}")
        true
      end

      def query_delayed?
        t = Bot::Storage.get("delay//#{query}") ||
            Bot::Storage.get("delay//#{query} #{driver.device}")
        if t && t.to_i > Time.now.to_i
          return (t.to_i - Time.now.to_i) / 60
        end
        Bot::Storage.del("delay//#{query}")
        Bot::Storage.del("delay//#{query} #{driver.device}")
        false
      end
    end
  end
end
