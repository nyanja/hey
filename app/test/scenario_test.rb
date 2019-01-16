# frozen_string_literal: true

require "minitest/autorun"
require "selenium-webdriver"
require "pry"

require_relative "../bot"

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
    @s = Bot::Runner.new core, "query"
    @res = @s.parse_results(@results)
  end

  # def test_handle_results
    # puts @res.map(&:inspect)
  # end

  def test_common
    puts @res&.map(&:inspect)
    # puts @s.try_to_defer_query.inspect
  end
end
