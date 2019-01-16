# frozen_string_literal: true

require_relative "behaviors/base"
require_relative "behaviors/target"
require_relative "behaviors/rival"

module Bot
  module Behaviors
    def target result, status
      Target.new(result, status)
    end

    def rival result, status
      Rival.new(result, status)
    end
  end
end
