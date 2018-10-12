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
    end
  end
end
