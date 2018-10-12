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
        return (t.to_i - Time.now.to_i) / 60 if t && t.to_i > Time.now.to_i
        Bot::Storage.del("delay//#{query}")
        Bot::Storage.del("delay//#{query} #{driver.device}")
        false
      end

      def defer_query
        log(:info, "Запрос отложен на #{config.query_skip_interval} мин.")
        Storage.set "delay//#{query} #{driver&.device}",
                    Time.now.to_i + config.query_skip_interval * 60
      end
    end
  end
end
