# frozen_string_literal: true

module Bot
  module Actions
    class RandomMouseMove < Base
      def perform
        return unless system?

        assign_coordinates
        assign_system_position
        puts "System Cords: #{@system_position.inspect}, " \
             "Screen Height: #{driver.screen_height / 4} ? #{@system_position[:y]}, " \
             "Screen Width: #{driver.screen_width / 4} ? #{@system_position[:x]}"
        swap_limits

        puts "Random Mouse Move coordinates: #{@x}, #{@y}"

        action
      end

      def system_action
        moving_iterations.times do
          `xdotool mousemove_relative --sync -- #{@x} #{@y}`
        end
      end

      def selenium_action
        nil
      end

      def assign_coordinates
        # TODO: take in to consideration page limits (width, height)
        # check in which side more space
        # move in that side
        # for values from configs
        @x = random_coord
        @y = random_coord
      end

      def swap_limits
        if @system_position[:x] < driver.screen_width / 3 && @x.negative? ||
           @system_position[:x] > (driver.screen_width / 3) * 2 && @x.positive?
          puts "Swapping #{@x}"
          @x * -1
        end
        if @system_position[:y] > driver.screen_height / 3 && @y.negative? ||
           @system_position[:y] < (driver.screen_height / 3) * 2 && @y.positive?
          puts "Swapping #{@y}"
          @y * -1
        end
      end

      def x_coords
        rand config.x_random_range
      end

      def y_coords
        rand config.y_random_range
      end

      def random_coord
        rand(-5..5)
      end

      def moving_iterations
        rand(2..10)
      end

      def system?
        config.random_mouse_move
      end
    end
  end
end
