# frozen_string_literal: true

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
        if t && t.to_i > Time.now.to_i && config.query_skip_on_limit
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

      # --------- Used in Results
      # не будет выполняться если нет цели на странице ИЛИ цели не в топе ИЛИ
      # первый мод И псевдо ниже игнорируемых О_о
      def try_to_defer_query
        no_target_on_the_page!
        targets_on_top!
        skipped_below_pseudo!
      end

      def no_target_on_the_page!
        return unless @targets.empty? && config.query_skip_on_presence?

        defer_query("Продвигаемого сайта нет на странице",
                    config.query_skip_on_presence_interval)
      end

      def targets_on_top!
        skip = config.query_skip_on_position_by_limit&.to_i
        return if @targets.empty? ||
                  skip.nil? ||
                  skip.zero? ||
                  skip - 1 < @targets.min ||
                  !config.query_skip_after_perform?

        defer_query("Продвигаемый сайт уже на высокой позиции",
                    config.query_skip_on_position_interval)
      end

      def skipped_below_pseudo!
        return unless config.mode == 1 &&
                      config.query_skip_on_non_pseudos_below_pseudo? &&
                      @pseudo && !@to_skip.empty? && @pseudo > @to_skip.min.to_i

        defer_query "Сайты к пропуску ниже доп. целевого"
      end

      def defer_query message, time = config.query_skip_interval
        log(:skip!, message)
        log(:info, "Запрос отложен на #{time} мин.")
        Storage.set "delay//#{query} #{driver&.device}",
                    Time.now.to_i + config.query_skip_interval * 60
        raise Errors::SkippingQuery
      end
    end
  end
end
