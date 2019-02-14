# frozen_string_literal: true

module Bot
  module Behaviors
    class Single < Base
      def initialize core, link, options = {}
        @core = core
        @link = link
        @options = options
        @visit_type = :link
      end

      def perform # rubocop:disable Metrics/AbcSize
        assign_scroll_percent
        navigate_inside_thread

        wait :pre_delay, behavior: true
        return kill_thread if scroll_percent.nil? || scroll_percent.zero?

        wait 10 # config for this wait?
        driver.js "window.stop()"
        print "  "
        driver.scroll_to(percent: scroll_percent, behavior: @visit_type)
        puts
      rescue Interrupt
        kill_thread
      ensure
        driver.quit if @options[:single_visit]
      end

      private

      def scroll_percent
        @scroll_percent ||= behavior_config(:scroll_height) ||
                            behavior_config(:scroll_height, :rival)
      end

      def assign_scroll_percent
        log(:link, "Прокрутка #{scroll_percent}%")
        set_pre_delay
      end

      def set_pre_delay
        return unless behavior_config(:pre_delay).positive? &&
                      scroll_percent.zero?

        driver.manage.timeouts.page_load = behavior_config(:pre_delay)
      end

      # To controll page download time - it'll stop after 10s
      def navigate_inside_thread
        @thread = Thread.new do
          driver.navigate.to(@link)
          # rescue Interrupt # _rubocop:disable Layout/RescueEnsureAlignment
          # exit
        rescue StandardError # _rubocop:disable Layout/RescueEnsureAlignment
          nil
        end
      end

      def kill_thread
        Thread.kill(@thread)
      end
    end
  end
end
