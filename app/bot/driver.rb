# frozen_string_literal: true

require "selenium-webdriver"

module Bot
  class Driver
    attr_reader :driver, :delay

    def initialize _
      @driver = Selenium::WebDriver.for :firefox
      @delay = Selenium::WebDriver::Wait.new(timeout: 15)
    end

    def respond_to_missing?
      true
    end

    def method_missing method, *args, &block
      super unless driver.respond_to? method
      driver.send method, *args
    end

    def type elem, str
      str.split("").each do |char|
        elem.send_keys char
        sleep rand(0.01..0.4)
      end
    end

    def wait &block
      delay.until(&block)
    end

    def js str
      driver.execute_script str
    end

    def y_offset
      js "return window.pageYOffset"
    end

    def scroll_to position
      (y_offset / 4).to_i.send((y_offset > position ? :downto : :upto),
                               (position / 4).to_i) do |y|
        js "window.scroll(\"0\", \"#{y * 4}\")"
      end
    end

    def scroll_by offset
      scroll_to y_offset + offset
    end

    def scroll_height
      js "return document.body.scrollHeight - window.innerHeight"
    end

    def switch_tab number
      switch_to.window(driver.window_handles[number])
    end
  end
end
