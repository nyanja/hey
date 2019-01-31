# frozen_string_literal: true

module Bot
  module Actions
    class MouseMove < Base
      private

      def system_action
        assign_coordinates

        loop do
          break unless @y_iterations.positive? || @x_iterations.positive?

          `xdotool mousemove_relative --sync -- #{x_move} #{y_move}`
          sleep behavior_config(:mouse_move_delay)
        end
        assign_system_position

        # make sure that it located correctly
        `xdotool mousemove --sync #{real_x} #{real_y}`
      end

      def selenium_action
        driver.move_to(element)
      end

      def assign_coordinates
        super

        unless y_vision?
          driver.scroll_to(x: @page_x, y: @page_y,
                           behavior: @options[:behavior])
          sleep 0.5
        end

        assign_system_position
        assign_offsets
        assign_iterations
      end

      def assign_offsets
        @offset_x = real_x - system_position_x
        @offset_y = real_y - system_position_y
      end

      def assign_iterations
        step = behavior_config(:mouse_move)
        @y_iterations = (@offset_y / step).abs
        @x_iterations = (@offset_x / step).abs

        @x_step = @offset_x.positive? ? step : step * -1
        @y_step = @offset_y.positive? ? step : step * -1
      end

      def y_move
        return 0 unless @y_iterations.positive?

        @y_iterations -= 1
        @y_step
      end

      def x_move
        return 0 unless @x_iterations.positive?

        @x_iterations -= 1
        @x_step
      end

      def system?
        behavior_config(:system_scroll)
      end
    end
  end
end
