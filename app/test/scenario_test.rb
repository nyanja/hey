# frozen_string_literal: true

require "minitest/autorun"
require "selenium-webdriver"
require "pry"

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
  Result = Struct.new(:text)
  def setup
    @results = [
      Result.new("ЯндексРеклама"),
      Result.new("meow"),
      Result.new("yurii"),
      Result.new("grach"),
      Result.new("nyan"),
      Result.new("khajiit"),
      Result.new("koshelka"),
      Result.new("çvêtoček"),
      Result.new("pálka")
    ]
    core = Bot::Core.new("./app/test/config_test.yml")
    @s = Bot::Scenario.new core, "query"
    @res = @s.parse_results(@results)
  end

  def test_handle_results
    puts @res.map(&:inspect)
  end
end
