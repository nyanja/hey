# frozen_string_literal: true

require "pry"
require "selenium-webdriver"
require "./app/bot/logger"
require "./app/bot/driver"
require "./app/bot/core"
require "./app/bot/scenario"
require "./app/bot/ip"
require "./app/bot/storage"

Bot::Core.new("./config.yml").execute
