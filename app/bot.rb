# frozen_string_literal: true

require "selenium-webdriver"

require_relative "bot/helpers/logger"
require_relative "bot/helpers/wait"
require_relative "bot/helpers/exception_handler"
require_relative "bot/helpers/sites"
require_relative "bot/storage"
require_relative "bot/ip"

require_relative "bot/helpers/config"
require_relative "bot/helpers/queries"
require_relative "bot/helpers/results"
require_relative "bot/scenarios/single"
require_relative "bot/runner"
require_relative "bot/driver"
require_relative "bot/core"

# require "require_all"
# require_rel "bot/"

module Bot
  def self.execute file_name
    Core.new(file_name).execute
  end
end
