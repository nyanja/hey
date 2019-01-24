# frozen_string_literal: true

module Bot
  module Actions
    class Scroll < Base
      def perform
        assign_coordinates
        assign_scroll_speed
        @offset = driver.y_offset
        # puts "Scroll. Offset: #{@offset}, Speed: #{@speed}, Y: #{@page_y}"

        action
      end

      private

      def action_logic
        loop do
          break if driver.y_vision?(@page_y)

          action
        end
      end

      # scroll_percent = scroll_height_link || scroll_height_non_target
      # depending on target or no there is some configs:
      # scroll_amount_target : scroll_amount
      # scroll_threashold & < scroll_height => amount * scroll_multiplier
      # scroll_delay_target : scroll_delay

      def system_action
        system("xdotool click --repeat #{@speed} " \
               "--delay #{@delay} #{click_button}")
        driver.random_mouse_move
      end

      def selenium_action
        # (@offset / @speed).to_i.send((@offset > @page_y ? :downto : :upto),
        #                              (@page_y / @speed).to_i) do |pixels|
        #   driver.js "window.scroll(\"0\", \"#{pixels * @speed}\")"
        # end
        driver.js "window.scroll(\"0\", \"#{@speed}\")"
        sleep delay
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

        speed = behavior_config :scroll_speed
        @speed = speed > 100 ? 100 : speed
      end

      def delay
        @delay ||= behavior_config :scroll_delay
      end
    end
  end
end
