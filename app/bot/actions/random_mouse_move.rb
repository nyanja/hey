# frozen_string_literal: true

module Bot
  module Actions
    class RandomMouseMove < Base
      def perform
        assign_coordinates
        puts "Here, coordinates: #{@x}, #{@y}"

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
        @x = random_coord
        @y = random_coord
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
