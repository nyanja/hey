# frozen_string_literal: true

module Bot
  module Helpers
    module Results
      def parse_results results = nil
        assign_variables(results)
        filter_results
        distribute_results
        assign_pseudo

        # check where returns nil...
        return if try_to_defer_query

        build_result
      end

      private

      def assign_variables results
        assign_search_results results
        @verified_results = []
        @actual_index = 0

        @to_skip = []
        @targets = []
        @rivals = []
      end

      def assign_search_results results
        @search_results = results || driver.find_element(class: "serp-list")
                                           .find_elements(class: "serp-item")
      end

      def filter_results
        @search_results.select! { |r| !skip_result?(r) && !invalid?(r) }
        @search_results = search_results.take(config.results_limit ||
                                              results.size)
      end

      def distribute_results
        search_results.each_with_index do |result, i|
          if to_skip?(result)
            @to_skip << i
          elsif target?(result)
            @targets << i
          elsif non_target?(result)
            @rivals << i
          end
        end
      end

      # Выбирает псевдо, если псевдо выпадает на игнорируемые/вражеские,
      # выбирает следующий результат в пределах допустимых индексов
      # псевдо кешируется и на следующем запросе будет следующий индекс
      def assign_pseudo previous_iteration = nil
        next_index = next_pseudo
        return if previous_iteration == next_index # when it can be?

        # в конфигах последовательность с рассчетом начала от 1
        real_index = (next_index + @targets.max.to_i || 1) - 1
        return assign_pseudo(real_index) if @to_skip.include?(real_index) ||
                                            @rivals.include?(real_index)

        @pseudo = real_index
      end

      # Будет выполняться Пока не (нет цели на странице // цели в топе // mrgl)
      # не будет выполняться если нет цели на странице ИЛИ цели не в топе ИЛИ
      # первый мод И псевдо ниже игнорируемых О_о
      def try_to_defer_query
        return unless no_target_on_the_page? ||
                      targets_on_top? ||
                      (config.mode == 1 && skipped_below_pseudo?)

        defer_query
        true
      end

      def build_result
        main = []

        @search_results.each_with_index do |result, i|
          @actual_index = i

          break if no_more_targets_below?

          status = assign_status
          if status == :main
            main << [result, status, @actual_index]
          else
            @verified_results << [result, status, @actual_index]
          end
        end
        @verified_results += main # main results at the end
      end

      def next_pseudo # rubocop:disable Metrics/AbcSize
        if @targets.empty?
          pseudos = config.solo_pseudo
          key = "psdk"
        else
          pseudos = config.pseudo
          key = "spsdk"
        end
        cached = Storage.get(key).to_i
        index = if cached >= pseudos.max || cached <= pseudos.min
                  pseudos.min
                else
                  cached + 1
                end
        Storage.set(key, index)
        index
      end

      def no_more_targets_below?
        @actual_index + 1 > config.results_count.to_i &&
          (@pseudo.nil? || @pseudo < @actual_index - @targets.max.to_i) &&
          (@targets.empty? || @targets.max < @actual_index)
      end

      def no_target_on_the_page?
        return unless @targets.empty? && config.query_skip_on_presence?

        log(:skip!, "Продвигаемого сайта нет на странице")
        true
      end

      def targets_on_top?
        skip = config.query_skip_on_position_by_limit
        return unless !@targets.empty? && skip && @targets.min <= skip.to_i

        log(:skip!, "Продвигаемый сайт уже на высокой позиции")
        return true unless config.query_skip_after_perform?

        defer_query
        nil
      end

      def skip_result? result
        return unless result.text.match?(config.ignore)

        log(:skip, result.text)
        true
      end

      def target? result
        result.text.match?(config.target)
      end

      def non_target? result
        config.non_target && result.text.match?(config.non_target)
      end

      def to_skip? result
        config.skip_site && result.text.match?(config.skip_site)
      end

      def skipped_below_pseudo?
        return unless config.query_skip_on_non_pseudos_below_pseudo? &&
                      @pseudo && @pseudo > @to_skip.min.to_i

        log(:skip!, "Сайты к пропуску ниже доп. целевого")
        true
      end

      def determine_status
        result_is_target? ||
          result_is_pseudo? ||
          (config.mode == 1 && result_is_rival?(result)) ||
          (config.mode == 1 && result_is_skip?)
      end

      def result_is_target?
        :main if @targets.include? @actual_index
      end

      def result_is_pseudo?
        :pseudo if @pseudo == @actual_index
      end

      def result_is_rival?
        :rival if @rivals.include? @actual_index
      end

      def result_is_skip?
        if @actual_index > config.results_count ||
           (config.skip && !config.non_target)
          :skip
        end
      end

      def result_is_invalid? result
        # ignore yandex turbo pages
        result.find_element(class: "overlay_js_intend")
        true
      rescue StandardError
        nil
      end

      def domain result = @result
        result.find_element(css: ".organic__subtitle .link b, " \
                                 ".organic__subtitle .link, " \
                                 ".serp-title_type_subtitle .link").text
      rescue Selenium::WebDriver::Error::NoSuchElementError => e
        # binding.pry
        log :error, "Нетипичная ссылка #{self.class}"
        puts e.backtrace
        "unknow"
      end
    end
  end
end
