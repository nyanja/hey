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
        elsif @options[:percent] # or config.scroll_percents ?
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
        @page_y = driver.page_height * @options[:percent] / 100
        @page_x = driver.page_width / 2
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
        driver.y_vision? y
      end
    end
  end
end
