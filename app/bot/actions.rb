# frozen_string_literal: true

module Bot
  module Actions
    require_relative "actions/base"
    require_relative "actions/scroll"
    require_relative "actions/mouse_move"
    require_relative "actions/random_mouse_move"

    def mouse_move opt = {}
      MouseMove.new(config, opt).perform
    end

    def random_mouse_move opt = {}
      RandomMouseMove.new(config, opt).perform
    end

    def scroll_to opt = {}
      Scroll.new(config, opt).perform
    end

    def click opt = {}
      Click.new(config, opt).perform
    end
  end
end
