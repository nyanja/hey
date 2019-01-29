# frozen_string_literal: true

module Bot
  module Actions
    class Scroll < Base
      def perform
        assign_coordinates
        assign_scroll_speed

        action
      end

      private

      # scroll_percent = scroll_height_link || scroll_height_non_target
      # depending on target or no there is some configs:
      # scroll_amount_target : scroll_amount
      # scroll_threashold & < scroll_height => amount * scroll_multiplier
      # scroll_delay_target : scroll_delay

      def system_action
        loop do
          break if driver.y_vision?(@page_y)

          system("xdotool click --repeat #{@speed} " \
                 "--delay #{@delay} #{click_button}")
          driver.random_mouse_move
        end
      end

      def selenium_action
        @offset = driver.y_offset
        puts "............................"
        puts "Scroll. Offset == #{@offset}, Speed == #{@speed}, Y == #{@page_y}"
        puts "............................"
        (@offset / @speed).to_i.send((@offset > @page_y ? :downto : :upto),
                                     iterations) do |iteration|
          # break if y_vision?
          if y_vision?
            puts "Stop scrolling because of vision. Iteration #{iteration} " \
                 "of #{iterations}"
            break
          end

          puts "    Scrolling to y == #{iteration * @speed}, offset: #{driver.y_offset}"
          driver.js "window.scroll({left: 0, top: #{iteration * @speed}, " \
                                   "behavior: 'smooth'})"
          sleep delay || 0.1
        end
        puts "Scroll finished y == #{@page_y}, offset: #{driver.y_offset} ............................."
      end

      def iterations
        return (@page_y / @speed).to_i if @options[:percent]

        ((@page_y - driver.screen_height / 2) / @speed).to_i
      end

      def selenium_iterations
        @page_y - driver.screen_heigh / 2
      end

      def click_button
        @offset < @page_y ? 5 : 4
      end

      def system?
        behavior_config :system_scroll
      end

      def assign_scroll_speed
        if @options[:scroll_speed]
          @speed = @options[:scroll_speed]
          return
        end

        @speed = behavior_config :scroll_speed
        check_speed_multiplier
        @speed = @speed > 150 ? 150 : @speed.to_i
      end

      def check_speed_multiplier
        return unless behavior_config(:threshold) &&
                      driver.page_height > behavior_config(:threshold).to_i

        @speed *= if behavior_config(:multiplier)
                    behavior_config(:multiplier).to_f
                  else
                    driver.page_height / behavior_config(:threshold).to_i
                  end
      end

      def delay
        behavior_config :scroll_delay
      end
    end
  end
end
