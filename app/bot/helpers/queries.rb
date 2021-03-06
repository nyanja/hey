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
        log :skip, "Продвижение неэффективно. Отложим до лучших времен..."
        driver.quit
        wait(:query_delay)
        true
      end

      def query_delayed?
        t = Bot::Storage.get("delay//#{query}") ||
            Bot::Storage.get("delay//#{query} #{driver.device}")
        if t && t.to_i > Time.now.to_i
          tt = (t.to_i - Time.now.to_i) / 60
          log :skip, "Запрос отложен. Осталось #{tt} мин."
          driver.quit
          wait(:query_delay)
          true
        else
          Bot::Storage.del("delay//#{query}")
          Bot::Storage.del("delay//#{query} #{driver.device}")
          false
        end
      end

      def defer_query
        log(:info, "Запрос отложен на #{config.query_skip_interval} мин.")
        Storage.set "delay//#{query} #{driver&.device}",
                    Time.now.to_i + config.query_skip_interval * 60
      end

      def assign_query_options q = nil
        match = (q || @query).match(/(.+) ~ ?(.+)/)
        return q || @query unless match

        quer = match[1]
        match[2].scan(/(?=-?)\w+/).each { |k| @query_options[k.to_sym] = true }
        @query = quer if q
        quer # костыли до релиза ветки mouse_feature
      end
    end
  end
end
