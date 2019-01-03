# frozen_string_literal: true

module Bot
  module Actions
    class MouseMove < Base
      def perform
        action
      end

      def system_action
        assign_coordinates
        driver.scroll(x: @x, y: @y) unless driver.y_vision?

        `xdotool mousemove #{system_x} #{system_y}`
      end

      def selenium_action
        driver.move_to(@options[:element]) if @options[:element]
      end

      def system?
        config.system_mouse_move
      end
    end
  end
end
