# frozen_string_literal: true

module Bot
  module Behaviors
    class Target
      def perform
        return if skip_target?

        assign_depth

        visit
        return unless @depth

        perform_depth_visits
      end

      def perform_depth_visits
        @depth.times do |t|
          view_page
          if @depth != t.succ
            # wait(:explore_delay)
            visit_some_link
          end
        rescue Selenium::WebDriver::Error::NoSuchElementError
          log(:error, "Нет подходящей ссылки для перехода")
        end
      end

      def view_page
        start_visit_time_counting
        wait 3
        print "  "
        # REPLACE
        # scroll(:target) while (driver.scroll_height - 10) >= driver.y_offset
        puts
        return unless rest_of_visit!.positive?

        wait @rest_of_visit / 8
        # REPLACE
        # driver.scroll_to 0
        wait @rest_of_visit if rest_of_visit!.positive?
      end

      def visit_some_link
        link = some_link
        return unless link

        log(:link, link.text)
        # REPLACE
        # driver.scroll_to(link.location.y - rand(120..220))
        wait :avg
        # REPLACE
        # link.click
      end

      def skip_target?
        # target can be skipped but not first from
        return unless config.skip_target &&
                      !@result.text.match?(config.target_patterns.first)

        log :"#{@visit_type}_target", "Пропуск неосновного сайта"
        true
      end

      def assign_depth
        @depth = config.explore_deepness if unique_ip?(@result)
        log :"#{@visit_type}_target", "глубина = #{@deth || 0}"
      end

      def last_path_link?
        config.last_path_link_target?
      end

      def pre_delay
        config.pre_delay_target
      end

      def min_visit
        config.min_visit_target
      end
    end
  end
end
