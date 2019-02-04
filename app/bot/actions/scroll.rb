# frozen_string_literal: true

module Bot
  module Actions
    class Scroll < Base
      def perform
        assign_coordinates
        assign_scroll_speed

        @thread = driver.random_mouse_move(behavior: @options[:behavior])
        action
      rescue Errors::ScrollLoop
        nil
      ensure
        Thread.kill(@thread) if @thread
      end

      private

      def system_action
        until y_vision?
          command = "xdotool click #{click_button}"

          # puts "System scroll: `#{command}`"
          @speed.to_i.times { system(command) }
          # driver.random_mouse_move(behavior: @options[:behavior])
          delay
        end
      end

      def selenium_action
        @offset = driver.y_offset
        (@offset / @speed).to_i.send((@offset > @page_y ? :downto : :upto),
                                     iterations) do |iteration|
          break if y_vision?

          driver.js "window.scroll({left: 0, top: #{iteration * @speed}, " \
                                   "behavior: 'smooth'})"
          delay
        end
      end

      def iterations
        return (@page_y / @speed).to_i if @options[:percent]

        ((@page_y - driver.screen_height / 2) / @speed).to_i
      end

      def selenium_iterations
        @page_y - driver.screen_heigh / 2
      end

      def click_button
        click_button = driver.y_offset < @page_y ? 5 : 4
        return @click_button = click_button unless @click_button

        if click_button != @click_button
          raise Errors::ScrollLoop if @speed <= 1
          @speed /= 2
        end
        @click_button = click_button
      end

      def system?
        behavior_config :system_scroll
      end

      def assign_scroll_speed
        @speed = behavior_config :scroll_speed
        check_speed_multiplier
        @speed = @speed > 150 ? 150 : @speed.to_i
      end

      def check_speed_multiplier
        return unless behavior_config(:scroll_threshold) &&
                      driver.page_height >
                      behavior_config(:scroll_threshold).to_i &&
                      multiplier > 1

        puts "Applying scroll multiplier: #{multiplier}, " \
             "new speed: #{@speed * multiplier}"
        @speed *= multiplier
      end

      def multiplier
        @multiplier ||= if behavior_config(:multiplier)
                          behavior_config(:multiplier).to_f
                        else
                          driver.page_height /
                            behavior_config(:scroll_threshold).to_i
                        end
      end

      def delay
        wait(:scroll_delay, behavior: true, skip_logs: true)
      end
    end
  end
end
