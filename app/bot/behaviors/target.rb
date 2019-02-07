# frozen_string_literal: true

module Bot
  module Behaviors
    class Target < Base
      def perform
        return if skip_target?

        assign_depth

        visit
        return if @depth&.zero?

        view_page
        return unless @depth

        perform_depth_visits
      end

      def perform_depth_visits
        @depth.times do |t|
          if @depth != t.succ
            wait(:explore_delay)
            visit_some_link
          end
          view_page
        rescue Selenium::WebDriver::Error::NoSuchElementError
          log(:error, "Нет подходящей ссылки для перехода")
        end
      end

      def view_page
        start_visit_time_counting
        wait 3
        print "  "
        driver.scroll_to(percent: behavior_config(:scroll_height),
                         behavior: @visit_type)
        puts
        return unless rest_of_visit!.positive?

        wait @rest_of_visit / 8
        driver.scroll_to(percent: 0, behavior: @visit_type)
        wait @rest_of_visit if rest_of_visit!.positive?
      end

      def visit_some_link
        link = some_link
        return unless link

        log(:link, link.text)
        driver.click(element: link, behavior: @visit_type)
      end

      def skip_target?
        # target can be skipped but not first from
        return unless behavior_config(:skip) &&
                      !@result.text.match?(behavior_config(:patterns).first)

        log :"#{@visit_type}_target", "Пропуск неосновного сайта"
        true
      end

      def assign_depth
        @depth = config.explore_deepness if unique_ip?
        log :"#{@visit_type}_target", "глубина = #{@deth || 0}"
      end
    end
  end
end