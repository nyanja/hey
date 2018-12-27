# frozen_string_literal: true

module Bot
  module Actions
    require_relative "actions/base"
    require_relative "actions/scroll"
    require_relative "actions/mouse_move"
    require_relative "actions/random_mouse_move"

    def mouse_move opt = {}
      MouseMove.new(driver, config, opt).perform
    end

    def random_mouse_move opt = {}
      RandomMouseMove.new(driver, config, opt).perform
    end

    def scroll_to opt = {}
      Scroll.new(driver, config, opt).perform
    end

    def click opt = {}
      Click.new(driver, config, opt).perform
    end
  end
end
