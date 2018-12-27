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

      def system_action
        loop do
          break if driver.y_vision?(@y)

          system("xdotool click #{@offset < @y ? 5 : 4} --sync " \
                 "--repeat #{@speed}")
          Actions.random_mouse_move(driver, config)
        end
      end

      def selenium_action
        (@offet / @speed).to_i.send((@offset > @y ? :downto : :upto),
                                    (@y / @speed).to_i) do |pixels|
          driver.js "window.scroll(\"0\", \"#{pixels * @speed}\")"
        end
      end

      def system?
        config.system_scroll
      end
    end
  end
end
