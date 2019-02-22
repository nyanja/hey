module Bot
  module Helpers
    module Coordinates
      def real_x
        @page_x - driver.x_offset
      end

      def real_y
        @page_y - driver.y_offset + driver.bars_height
      end

      def system_position_x
        @system_position[:x]
      end

      def system_position_y
        @system_position[:y]
      end

      def assign_coordinates
        if @options[:x] && @options[:y]
          @page_x = @options[:x]
          @page_y = @options[:y]
        elsif element
          element_coordinates
        elsif @options[:percent]
          percent_coordinates
        else
          raise Errors::MissingAttribute, "There is no coordinates"
        end
      end

      def element_coordinates
        point = element&.rect
        raise Errors::NotFound, "Element was not found" unless point

        @page_x = point.x + point.width / 2
        @page_y = point.y + point.height / 2
      end

      def percent_coordinates
        if @options[:percent].is_a?(TrueClass)
          @options[:percent] = behavior_config(:scroll_height)
        end

        @page_y = if @options[:percent] > page_footer_offset
                    driver.page_height - driver.screen_height * 1.5
                  else
                    driver.page_height * @options[:percent] / 100
                  end
        @page_x = driver.page_width / 2
      end

      def page_footer_offset
        100 - driver.screen_height / (driver.page_height / 100)
      end

      def assign_system_position
        # "x:123 y:321 screen:0 window:123142132"
        cords = `xdotool getmouselocation`
        match = cords.match(/x:(\d+) y:(\d+)/)
        @system_position = { x: match[1].to_i, y: match[2].to_i }
      end

      def correct_position?
        assign_system_position
        system_position_x == real_x && system_position_y == real_y
      end

      def y_vision? y = @page_y
        offset = y_target(y)
        # puts "Inside y_vision: y == #{y}, offset == #{offset},
        #       options: #{@options}"
        y > offset - 100 && offset + 100 > y
      end

      def y_targety y = @page_y
        y_offset = driver.y_offset
        if @options[:percent] || y_offset + driver.screen_height / 2 > y
          driver.y_offset
        else
          driver.y_offset + driver.screen_height / 2
        end
      end
    end
  end
end
