# frozen_string_literal: true

module Bot
  module Actions
    class Click < Base
      def perform
        action
      end

      # def system_action
      # end

      def selenium_action
        (@options[:element] || driver).find_element(@options[:query]).click
      end

      def system?
        false # config.system_mouse_move
      end
    end
  end
end
