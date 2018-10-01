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
        Strorage.del("qc//#{query}")
        true
      end

      def query_delayed?
        t = Storage.get("delay//#{query}") ||
            Storage.get("delay//#{query} #{driver.device}")
        return true if t && t.to_i < Time.now.to_i
        Storage.del("delay//#{query}")
        Storage.del("delay//#{query} #{driver.device}")
        false
      end
    end
  end
end
