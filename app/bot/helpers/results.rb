# frozen_string_literal: true

# Модуль предназначенный для парсинга результатов поиска и их "представлении"
# Предстоит разделить на объекты. Будет круто сделать `Query` объект
# Query будет хранить в себе результаты и данные относящиеся к этому запросу.
# Результаты будут представлены объектами `Target`, `Ignored`, `Rival`

module Bot
  module Helpers
    module Results
      # Парсит результаты поискового запроса
      def parse_results results = nil
        assign_variables(results)
        filter_results
        distribute_results
        assign_pseudo

        try_to_defer_query

        build_result
        output_results
        @verified_results
      rescue Errors::SkippingQuery
        nil
      end

      def assign_search_results results = nil
        @search_results = results || driver.find_element(class: "serp-list")
                                           .find_elements(class: "serp-item")
      end

      private

      def assign_variables results
        assign_search_results results
        @verified_results = []
        @actual_index = 0

        @to_skip = []
        @targets = []
        @rivals = []

        @target_domains = []
        @results_count = config.results_count.to_i + 1
      end

      def filter_results
        @search_results.select! { |r| !skip_result?(r) && result_is_valid?(r) }
        @search_results = @search_results.take(config.results_limit ||
                                               results.size)
      end

      def distribute_results
        @search_results.each_with_index do |result, i|
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
        return if !next_index ||
                  previous_iteration == next_index # when it can be?

        # в конфигах последовательность с рассчетом начала от 1
        real_index = (next_index + @targets.max.to_i || 1) - 1
        return assign_pseudo(real_index) if @to_skip.include?(real_index) ||
                                            @rivals.include?(real_index)

        @pseudo = real_index
      end

      def build_result
        target = []

        @search_results.each_with_index do |result, i|
          @actual_index = i

          break if no_more_targets_below?

          status = assign_status
          if status == :target
            target << [result, status, @actual_index]
          else
            @verified_results << [result, status, @actual_index]
          end
        end
        @verified_results += target # target results at the end
      end

      def output_results
        puts "Результаты:"
        @verified_results.each do |result|
          puts "  #{result[2] + 1} - #{result[1]} - #{domain(result[0])}"
        end
      end

      def next_pseudo # rubocop:disable Metrics/AbcSize
        if @targets.empty?
          pseudos = config.sole_pseudo_targets || config.pseudo_targets
          key = "psdk"
        else
          pseudos = config.pseudo_targets
          key = "spsdk"
        end
        return unless pseudos

        cached = Storage.get(key).to_i
        index = if cached >= pseudos.max || cached < pseudos.min
                  pseudos.min
                else
                  cached + 1
                end
        Storage.set(key, index)
        index
      end

      def no_more_targets_below?
        @actual_index > @results_count &&
          (@pseudo.nil? || @pseudo < @actual_index) && # - indx @targets.max.to_i
          (@targets.empty? || @targets.max < @actual_index)
      end

      def skip_result? result
        return unless result.text.match?(config.ignore)

        log(:skip, result.text)
        true
      end

      def target? result
        config.target && result.text.match?(config.target)
      end

      def non_target? result
        config.rival && result.text.match?(config.rival)
      end

      def to_skip? result
        config.skip_site && result.text.match?(config.skip_site)
      end

      def assign_status
        result_is_target? ||
          result_is_pseudo? ||
          (config.mode == 1 && result_is_rival?) ||
          (config.mode == 1 && result_is_skip?)
      end

      def result_is_target?
        return unless @targets.include?(@actual_index)

        result = @search_results[@actual_index]
        d = domain(result)
        return :skip if @target_domains.include?(d) ||
                        @query_options[:skip_target]

        @target_domains << d
        :target
      end

      def result_is_pseudo?
        :pseudo if @pseudo == @actual_index
      end

      def result_is_rival?
        :rival if @rivals.include?(@actual_index) ||
                  !config.rival && @actual_index < config.results_count
      end

      def result_is_skip?
        :skip
      end

      def result_is_valid? result
        # ignore yandex turbo pages
        result.find_element(class: "overlay_js_intend")
        false
      rescue StandardError
        true
      end

      def domain result = @result
        return result.domain unless result.respond_to? :find_element # for tests

        result.find_element(css: ".organic__subtitle .link b, " \
                                 ".organic__subtitle .link, " \
                                 ".serp-title_type_subtitle .link").text
      rescue Selenium::WebDriver::Error::NoSuchElementError => e
        log :error, "Нетипичная ссылка #{e.class}"
        "unknow"
      end
    end
  end
end
