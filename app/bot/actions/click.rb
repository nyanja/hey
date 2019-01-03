# frozen_string_literal: true

module Bot
  module Actions
    class Click < Base
      def perform
        action
      end

      def system_action
        assign_coordinates
        driver.mouse_move(x: @x, y: @y) unless correct_position?

        `xdotool click 1`
      end

      def selenium_action
        element.click
      end

      def system?
        false # config.system_mouse_move
      end
    end
  end
end
