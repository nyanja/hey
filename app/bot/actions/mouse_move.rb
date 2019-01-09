# frozen_string_literal: true

module Bot
  module Actions
    class MouseMove < Base
      def perform
        action
      end

      def system_action
        assign_coordinates
        unless driver.y_vision?(@y)
          driver.scroll_to(x: @x, y: @y)
        end

        puts "System Mouse Move #{system_x} #{system_y}"
        `xdotool mousemove #{system_x} #{system_y}`
      end

      def selenium_action
        driver.move_to(@options[:element]) if @options[:element]
      end

      def system?
        config.system_scroll
      end
    end
  end
end
