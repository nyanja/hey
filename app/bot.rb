# frozen_string_literal: true

require "selenium-webdriver"

# TODO: split this list in to logical modules which will be required.
# require_relative "bot/helpers"
# require_relative "bot/base" ?

require_relative "bot/errors"
require_relative "bot/helpers/coordinates"
require_relative "bot/actions"

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

module Bot
  def self.execute file_name
    Core.new(file_name).execute
  end
end
