# frozen_string_literal: true

module Bot
  module Actions
    class Click < Base
      private

      def system_action
        assign_coordinates
        unless correct_position?
          driver.mouse_move(x: @page_x, y: @page_y,
                            behavior: @options[:behavior])
        end
        puts "System Click"

        `xdotool click 1`
      end

      def selenium_action
        assign_coordinates
        unless y_vision?
          puts "Scroll Inside Click!!! ----------------------------"
          driver.scroll_to(x: @page_x, y: @page_y)
          sleep 1
        end
      rescue Errors::MissingAttribute # rubocop:disable Lint/HandleExceptions
      ensure
        element.click
      end

      def system?
        behavior_config :system_click # config.system_click
      end
    end
  end
end
