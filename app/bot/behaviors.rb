# frozen_string_literal: true

require_relative "behaviors/base"
require_relative "behaviors/target"
require_relative "behaviors/rival"
require_relative "behaviors/lite"
require_relative "behaviors/single"

module Bot
  module Behaviors
    # может быть пропущено -> visit -> scroll_to the end -> глубинные посещения
    def apply_target_behavior result, status
      Target.new(core, result, status).perform
    end

    # visit -> some scroll -> additional_visits
    # 10 seconds wait -_- window.stop -> play it with thread?
    def apply_rival_behavior result, status
      Rival.new(core, result, status).perform
    end

    # just visit
    def apply_lite_behavior result, status, index
      Lite.new(core, result, status).perform index
    end

    # visit: click on link, wait, checkout to new window

    # navigate inside thread -> wait -> wait again -> scroll -> exit
    def perform_single_visit_behavior link
      self.class.perform_single_visit_behavior(core, link)
    end

    def self.perform_single_visit_behavior core, link
      Single.new(core, link).perform
    end
  end
end
