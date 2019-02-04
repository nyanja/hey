# frozen_string_literal: true

require "minitest/autorun"
require "selenium-webdriver"
require "pry"

require_relative "../bot"

class ScenarioTest < Minitest::Test
  Result = Struct.new(:text, :domain)
  def setup
    @results = [
      Result.new("ЯндексРеклама", "yandex"),
      Result.new("meow", "lider"),
      Result.new("yurii", "lider"),
      Result.new("grach", "cawcaw"),
      Result.new("nyan", "cache"),
      Result.new("khajiit", "lal"),
      Result.new("koshelka", "ka"),
      Result.new("çvêtoček", "vmer"),
      Result.new("pálka", "lider")
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
