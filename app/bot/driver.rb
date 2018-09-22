# frozen_string_literal: true

module Bot
  class Driver
    attr_reader :driver, :core, :delay

    extend Forwardable
    def_delegator :core, :config

    def initialize core
      @core = core
      # @driver = Selenium::WebDriver.for :firefox, options: opts
      @driver = Selenium::WebDriver.for :chrome, options: driver_options
    end

    def driver_options
      # opts = Selenium::WebDriver::Firefox::Options.new
      # opts.add_preference "general.useragent.override", config.user_agent
      opts = Selenium::WebDriver::Chrome::Options.new
      opts.add_argument "--incognito"
      opts.add_argument "--kiosk"
      # opts.add_argument "--force-desktop"
      # opts.add_argument "--force-desktop[6]"

      # opts.add_argument "--proxy-server=185.14.6.134:8080"
      opts.add_argument "--proxy-server=#{config.proxy}" if config.use_proxy?
      opts.add_argument "--user-agent=#{config.user_agent}"
    end

    def respond_to_missing? method
      driver.respond_to?(method)
    end

    def method_missing method, *args, &block
      super unless respond_to_missing?(method)
      driver.send method, *args
    end

    def type elem, str
      str.split("").each do |char|
        elem.send_keys char
        sleep rand(0.01..0.4)
      end
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

    def close_all_tabs
      driver.quit
      # driver.window_handles.each do |id|
      # switch_to.window id
      # close
      # end
    end

    def close_active_tab *logger_params
      driver&.close
      driver&.switch_tab 0
      log(*logger_params) if logger_params&.any?
    end

    def clean_up
      driver.close_all_tabs
    end

    def click query, element = driver
      element.find_element(query).click
    end
  end
end
