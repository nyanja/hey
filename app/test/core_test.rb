# frozen_string_literal: true

require "minitest/autorun"
require "./app/bot/core.rb"

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
