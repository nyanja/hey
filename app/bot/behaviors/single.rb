# frozen_string_literal: true

module Bot
  module Behaviors
    class Single < Base
      def initialize core, link
        @core = core
        @link = link
      end

      def perform
        assign_scroll_percent
        navigate_inside_thread

        wait :pre_delay_link
        return kill_thread if @scroll_percent.nil? || @scroll_percent.zero?

        wait 10 # config for this wait?
        driver.js "window.stop()"
        print "  "
        # REPLACE
        # scroll while (driver.scroll_height * 0.01 * scroll_percent) > driver.y_offset
        puts
      rescue Interrupt
        kill_thread
      ensure
        driver.quit
      end

      private

      def assign_scroll_percent
        @scroll_percent = config.scroll_height_link ||
                          config.scroll_height_non_target
        log(:link, "прокрутка #{@scroll_percent}%")
        set_pre_delay
      end

      def set_pre_delay
        return unless config.pre_delay_link.positive? && @scroll_percent.zero?

        driver.manage.timeouts.page_load = config.pre_delay_link
      end

      # To controll page download time - it'll stop after 10s
      def navigate_inside_thread
        @thread = Thread.new do
          driver.navigate.to(@query)
        # rescue Interrupt # _rubocop:disable Layout/RescueEnsureAlignment
        # exit
        rescue StandardError # rubocop:disable Layout/RescueEnsureAlignment
          nil
        end
      end

      def kill_thread
        Thread.kill(@thread)
      end
    end
  end
end
