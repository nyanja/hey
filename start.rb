# frozen_string_literal: true

require "pry"
require "yaml"
require "selenium-webdriver"
require "./app/bot/driver"
require "./app/bot/core"
require "./app/bot/scenario"

Bot::Core.new(YAML.load_file("./config.yml")).execute
