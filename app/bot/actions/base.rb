module Bot
  module Actions
    class Base
      include Bot::Helpers::Coordinates

      attr_reader :driver, :config, :options

      def initialize driver, config, options = {}
        @driver = driver
        @config = config
        @options = options
      end

      def perform *args
        action(*args)
      end

      private

      def action *args
        return system_action(*args) if system?

        selenium_action(*args)
      end

      def behavior_config name
        config.send "#{@options[:behavior] || :search}_#{name}"
      end

      def system?
        config.system_actions
      end

      def target?
        @options[:target]
      end

      def element
        @element ||= assign_element
      end

      def assign_element
        if @options[:query]
          (@options[:element] || driver).find_element(@options[:query])
        elsif @options[:element]
          @options[:element]
          # else
          # raise Errors::NotFound, "Element was not found"
        end
      end
    end
  end
end
