# frozen_string_literal: true

module Bot
  module Actions
    class Scroll < Base
      def perform
        assign_coordinates
        @speed = config.scroll_speed(@options[:target])
        @offset = driver.y_offset

        action
      end

      private

      def system_action
        puts "System Scroll. Offset: #{@offset}, Speed: #{@speed}, Y: #{@page_y}"
        loop do
          break if driver.y_vision?(@page_y)

          system("xdotool click --repeat #{@speed} #{@offset < @page_y ? 5 : 4}")
          driver.random_mouse_move
        end
      end

      def selenium_action
        (@offset / @speed).to_i.send((@offset > @page_y ? :downto : :upto),
                                    (@page_y / @speed).to_i) do |pixels|
          driver.js "window.scroll(\"0\", \"#{pixels * @speed}\")"
        end
      end

      def system?
        config.system_scroll
      end
    end
  end
end
