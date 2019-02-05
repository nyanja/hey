# coding: utf-8
# frozen_string_literal: true

module Bot
  module Behaviors
    class Rival < Base
      def perform
        return unless unique_ip?

        log(:non_target, "прокрутка #{scroll_percent}%")
        visit
        return if scroll_percent.nil? || scroll_percent.zero?

        view_page

        additional_visits if @visit_type == :rival
      end

      def view_page
        # need same as somewhere visit inside thread
        start_visit_time_counting
        # wait 10
        # driver.js "window.stop()"
        print "  "
        driver.scroll_to(percent: scroll_percent, behavior: @visit_type)
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
    end
  end
end
