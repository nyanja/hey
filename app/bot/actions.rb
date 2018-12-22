# frozen_string_literal: true

module Bot
  module Actions
    require_relative "actions/base"
    require_relative "actions/mouse_move"

    def mouse_move *args
      MouseMove.new(driver, config).perform(*args)
    end

    def random_mouse_move *args
      # MouseMove.new(driver, config).perform_random(*args)
    end

    def scroll_to *args
      # Scroll.new(driver, config).perform(*args)
    end

    def click *args
      # Click.new(driver, config).perform(*args)
    end
  end
end
