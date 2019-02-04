# frozen_string_literal: true

module Bot
  module Actions
    class RandomMouseMove < Base
      def perform
        return unless system?

        Thread.new do
          loop do
            assign_coordinates

            action
          end
        end
      end

      private

      def system_action
        behavior_config(:random_moving_iterations)&.times do
          `xdotool mousemove_relative --sync -- #{@x} #{@y}`
          wait(:random_moving_delay,
               skip_logs: false, behavior: true)
        end
        wait(:random_moving_delay_after_iterations,
             skip_logs: true, behavior: true)
      end

      def selenium_action
        nil
      end

      def assign_coordinates
        @x = behavior_config(:random_move_by_x)
        @y = behavior_config(:random_move_by_y)

        assign_system_position
        swap_limits

        # puts "Random Mouse Move: {x: #{@x}, y: #{@y}}"
      end

      def swap_limits
        if system_position_x < driver.screen_width / 3 && @x.negative? ||
           system_position_x > (driver.screen_width / 3) * 2 && @x.positive?
          # puts "Swapping X #{@x}, position: #{system_position_x}, " \
          # "size: #{driver.screen_width / 3}"
          @x *= -1
        end
        if system_position_y < driver.screen_height / 3 && @y.negative? ||
           system_position_y > (driver.screen_height / 3) * 2 && @y.positive?
          # puts "Swapping Y #{@y}, position: #{system_position_y}, " \
          # "size: #{driver.screen_height / 3}"
          @y *= -1
        end
      end

      def system?
        behavior_config(:random_mouse_move)
      end
    end
  end
end
