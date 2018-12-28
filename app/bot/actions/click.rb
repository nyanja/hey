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
        element.click
      end

      def system?
        false # config.system_mouse_move
      end
    end
  end
end
