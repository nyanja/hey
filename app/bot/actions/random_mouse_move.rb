# frozen_string_literal: true

module Bot
  module Actions
    class RandomMouseMove < Base
      def perform
        return unless system?

        assign_coordinates

        action
      end

      private

      def system_action
        config.random_moving_iterations.times do
          `xdotool mousemove_relative --sync -- #{@x} #{@y}`
        end
      end

      def selenium_action
        nil
      end

      def assign_coordinates
        @x = config.random_move_by_x
        @y = config.random_move_by_y

        assign_system_position
        swap_limits

        puts "Random Mouse Move: {x: #{@x}, y: #{@y}}"
      end

      def swap_limits
        if @system_position[:x] < driver.screen_width / 3 && @x.negative? ||
           @system_position[:x] > (driver.screen_width / 3) * 2 && @x.positive?
          puts "Swapping X #{@x}, position: #{@system_position[:x]}, " \
               "size: #{driver.screen_width / 3}"
          @x *= -1
        end
        if @system_position[:y] < driver.screen_height / 3 && @y.negative? ||
           @system_position[:y] > (driver.screen_height / 3) * 2 && @y.positive?
          puts "Swapping Y #{@y}, position: #{@system_position[:y]}, " \
               "size: #{driver.screen_height / 3}"
          @y *= -1
        end
      end

      def system?
        config.random_mouse_move
      end
    end
  end
end
