# frozen_string_literal: true

require_relative "bot/helpers/waiter"
require_relative "bot/helpers/exception_handler"
require_relative "bot/helpers/logger"
require_relative "bot/storage"
require_relative "bot/ip"

require_relative "bot/helpers/config"
require_relative "bot/scenario"
require_relative "bot/driver"
require_relative "bot/core"

# require "require_all"
# require_rel "bot/"

module Bot
  def self.execute file_name
    Core.new(file_name).execute
  end
end
