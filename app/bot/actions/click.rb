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

        `xdotool click 1`
      end

      def selenium_action
        assign_coordinates
        unless y_vision?
          driver.scroll_to(x: @page_x, y: @page_y)
          sleep 1
        end
      rescue Errors::MissingAttribute # rubocop:disable Lint/HandleExceptions
      ensure
        element.click
      end

      def system?
        if behavior_config(:system_click) && behavior_config(:system_scroll)
          true
        elsif behavior_config(:system_click)
          puts "Системный клик мышкой не может работать без системного скролла"
          false
        end
      end
    end
  end
end
