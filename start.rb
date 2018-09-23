# frozen_string_literal: true

require "pry"
require "selenium-webdriver"

require "./app/bot"

Bot.execute("./config_example.yml")
