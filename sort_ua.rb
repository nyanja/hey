# frozen_string_literal: true

require "./ua.rb"
require "browser"

UA_MOBILE = []
UA_DESKTOP = []

UA.each do |ua|
  browser = Browser.new(ua)
  (browser.device.mobile? || browser.device.tablet? ? UA_MOBILE : UA_DESKTOP) << ua
end

UA_MOBILE.freeze
UA_DESKTOP.freeze
