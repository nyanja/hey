module Bot
  module Actions
    class Base
      attr_reader :driver, :config, :options

      def initialize driver, config, options = {}
        @driver = driver
        @config = config
        @options = options
        # @@browser_offset
      end

      def action *args
        return system_action(*args) if system?

        selenium_action(*args)
      end

      def system?
        config.system_actions
      end

      # TODO: separate class for coordinates?
      # driver.y_offset - how far from page start
      # driver.manage.window.size # struct with heigh && width
      # window.screen.availHeight - screen height excluding bars
      def assign_coordinates
        if @options[:x] && @options[:y]
          @x = @options[:x]
          @y = @options[:y]
        elsif @options[:element]
          point = @options[:element]&.rect
          raise Errors::NotFound, "Element was not found" unless point

          @x = point.x + point.width / 2
          @y = point.y + point.height / 2
        elsif @options[:percent] # or config.scroll_percents ?
          @y = driver.page_height * @options[:percent] / 100
          @x = driver.page_width / 2
        end
      end

      def set_element element
        @element = element
      end

      # def current_position_on_page
      # driver.y_offset
      # end
    end
  end
end
