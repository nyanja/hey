# frozen_string_literal: true

module Bot
  module Actions
    class Click < Base
      private

      def system_action
        assign_coordinates
        driver.mouse_move(x: @page_x, y: @page_y) unless correct_position?
        puts "System Click"

        `xdotool click 1`
      end

      def selenium_action
        element.click
      end

      def system?
        config.system_click
      end
    end
  end
end
