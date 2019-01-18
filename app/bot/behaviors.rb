# frozen_string_literal: true

require_relative "behaviors/base"
require_relative "behaviors/target"
require_relative "behaviors/rival"

module Bot
  module Behaviors
    # common: domain, visit

    def apply_target_behavior result, status
      Target.new(core, result, status).perform
    end

    def apply_rival_behavior result, status
      Rival.new(core, result, status).perform
    end

    def apply_lite_behavior result, status, index
      Lite.new(core, result, status).perform index
    end

    # single visit

    def perform_single_visit link
      self.class.perform_single_visit(core, link)
    end

    def self.perform_single_visit core, link
      Single.new(core, link).perform
    end
  end
end
