# frozen_string_literal: true

module Bot
  module Behaviors
    class Rival < Base
      def perform
        return unless unique_ip? @result

        log(:non_target, "прокрутка #{scroll_percent}%")
        visit
        return if scroll_percent.nil? || scroll_percent.zero?

        view_page

        additional_visits if visit_type == :rival
      end

      def view_page
        # need same as somewhere visit inside thread
        @start_time = Time.now.to_i
        wait 10
        driver.js "window.stop()"
        print "  "
        # REPLACE
        # scroll while (driver.scroll_height * 0.01 * scroll_percent) > driver.y_offset
        puts
        return unless rest_of_visit!.positive?

        wait(@rest_of_visit)
      end

      def additional_visits
        return if config.additional_visits&.empty?

        config.additional_visits.each do |link|
          Behaviors.perform_single_visit_behavior(core, link)
        end
      end

      def scroll_percent
        @scroll_percent ||= config.scroll_height_non_target
      end

      def last_path_link?
        config.last_path_link_rival?
      end

      def pre_delay
        config.pre_delay_non_target
      end

      def min_visit
        config.min_visit_non_target
      end
    end
  end
end
