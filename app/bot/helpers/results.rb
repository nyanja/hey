module Bot
  module Helpers
    module Results
      def remove_skips_from! results
        results.reduce([]) do |acc, result|
          next acc if skip_result?(result) || invalid?(result)
          acc << result
        end
      end

      def no_more_targets_below?
        @actual_index > config.results_count.to_i &&
          (@pseudos.empty? || @pseudos.max < @actual_index - @targets.last.to_i) &&
          (@targets.empty? || @targets.max < @actual_index)
      end

      def domain result
        return result.domain unless result.respond_to? :find_element # for tests

        result.find_element(css: ".organic__subtitle .link b, .organic__subtitle .link, .serp-title_type_subtitle .link").text
      rescue Selenium::WebDriver::Error::NoSuchElementError => e
        # binding.pry
        log :error, "Нетипичная ссылка #{self.class}"
        puts e.backtrace
        "unknow"
      end
    end
  end
end
