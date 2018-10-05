# frozen_string_literal: true

require "minitest/autorun"

require_relative "../bot/helpers/logger"
require_relative "../bot/helpers/wait"
require_relative "../bot/helpers/exception_handler"
require_relative "../bot/helpers/sites"
require_relative "../bot/storage"
require_relative "../bot/ip"

require_relative "../bot/helpers/config"
require_relative "../bot/helpers/queries"
require_relative "../bot/scenario"
require_relative "../bot/driver"
require_relative "../bot/core"

class ScenarioTest < Minitest::Test
  def setup
  end

end
