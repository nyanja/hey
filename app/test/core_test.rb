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
require_relative "../bot/helpers/results"
require_relative "../bot/scenario"
require_relative "../bot/driver"
require_relative "../bot/core"

class CoreTest < Minitest::Test
  def setup
    @c = Bot::Core.new "./app/test/config_test.yml"
  end

  def test_config_random_from_range
    # integer from 20 to 30
    value = @c.config.integer
    assert value.integer?
    assert value >= 20 && value <= 30
  end

  def test_config_regexp
    value = @c.config.regexp
    assert_equal(/че-лов.ек|моле кула/i, value)
  end
end
