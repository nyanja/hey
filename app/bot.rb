# frozen_string_literal: true

require "selenium-webdriver"

require_relative "bot/errors"
require_relative "bot/helpers"
require_relative "bot/actions"

require_relative "bot/storage"
require_relative "bot/ip"

require_relative "bot/behaviors"
require_relative "bot/scenarios"
require_relative "bot/driver"
require_relative "bot/core"

module Bot
  def self.execute file_name
    Core.new(file_name).execute
  end
end
