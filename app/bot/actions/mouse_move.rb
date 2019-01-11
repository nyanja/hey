# frozen_string_literal: true

module Bot
  module Actions
    class MouseMove < Base
      def perform
        action
      end

      private

      def system_action
        assign_coordinates

        puts "System Mouse Move #{real_x} #{real_y}"
        loop do
          break unless @y_iterations.positive? && @x_iterations.positive?

          `xdotool mousemove_relative --sync -- #{x_move} #{y_move}`
          sleep config.system_mouse_move_delay
        end
        # make sure that it located correctly
        `xdotool mousemove #{real_x} #{real_y}`
      end

      def selenium_action
        driver.move_to(@options[:element]) if @options[:element]
      end

      def assign_coordinates
        super

        driver.scroll_to(x: @page_x, y: @page_y) unless y_vision?

        assign_system_position
        assign_offsets
        assign_iterations
      end

      def assign_offsets
        @offset_x = system_position_x - real_x
        @offset_y = system_position_y - real_y
      end

      def assign_iterations
        step = config.system_mouse_move
        @y_iterations = (@offset_y / step).abs
        @x_iterations = (@offset_x / step).abs

        @x_step = @offset_x.positive? ? step : step * -1
        @y_step = @offset_y.positive? ? step : step * -1
      end

      def y_move
        return 0 if @y_iterations.zero?

        @y_iterations -= 1
        @y_step
      end

      def x_move
        return 0 if @x_iterations.zero?

        @x_iterations -= 1
        @x_step
      end

      def system?
        config.system_scroll
      end
    end
  end
end
