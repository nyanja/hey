# frozen_string_literal: true

require "browser"

require "./sort_ua.rb"

module Bot
  class Driver
    attr_reader :driver, :core, :delay, :browser, :screen_height, :screen_width,
                :bars_height, :user_agent

    extend Forwardable
    def_delegator :core, :config

    include Helpers::Logger
    include Actions

    def initialize core, opts = {}
      @core = core
      # @driver = Selenium::WebDriver.for :firefox, options: driver_options
      client = Selenium::WebDriver::Remote::Http::Default.new
      client.open_timeout = 200 # seconds
      client.read_timeout = 200
      @driver = Selenium::WebDriver.for :chrome,
                                        options: driver_options(opts),
                                        http_client: client
      @driver.network_conditions = { offline: false,
                                     latency: config.throttling_latency,
                                     throughput:
                                      1024 * config.throttling_trhoughput }

      window = @driver.manage.window.size
      @screen_height = window.height
      @screen_width = window.width
      @bars_height = @screen_height - inner_height
      # @driver.manage.window.maximize # some issue with system controls
    end

    def driver_options opts
      @user_agent = opts[:user_agent] ||
                    if config.use_real_ua?
                      (config.mobile ? UA_MOBILE : UA_DESKTOP).sample
                    else
                      config.mobile ? config.mobile_ua : config.desktop_ua
                    end
      @browser = Browser.new(@user_agent)

      # opts = Selenium::WebDriver::Firefox::Options.new
      # opts.add_preference "general.useragent.override", user_agent
      opts = Selenium::WebDriver::Chrome::Options.new
      opts.add_argument "--incognito"
      opts.add_argument "--kiosk" # unless config.mode == 3
      # opts.add_argument "--force-desktop"
      # opts.add_argument "--force-desktop[6]"

      # opts.add_argument "--proxy-server=185.14.6.134:8080"
      opts.add_argument "--proxy-server=#{config.proxy}" if config.use_proxy?

      puts "  %s" % @user_agent
      opts.add_argument "--user-agent=#{@user_agent}"
      opts
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
      js("return window.pageYOffset")
    end

    def x_offset
      js("return window.pageXOffset")
    end

    def y_point
      y_offet + @screen_height / 2
    end

    def y_vision? y, opts = {}
      offset = if opts[:percent]
                 y_offset
               else
                 y_offset + @screen_height / 2
               end
      # puts "Inside y_vision: y == #{y}, offset == #{offset}, opts == #{opts}"
      y > offset - 100 && offset + 100 > y
    end

    def page_height
      wait_until { driver.find_element(:tag_name, "body") }
        .attribute("scrollHeight").to_i
    end

    def page_width
      wait_until { driver.find_element(:tag_name, "body") }
        .attribute("scrollWidth").to_i
    end

    # wtf? innerHeight == browser screen for site - without bars and so on.
    def scroll_height
      js "return document.body.scrollHeight - window.innerHeight"
    end

    def switch_tab number
      switch_to.window(driver.window_handles[number])
    end

    def close_tab second_call = nil
      driver.close if driver.window_handles.count > 1
      switch_tab 0
    rescue IOError => e
      raise e if second_call
      sleep 1
      close_tab true
    end

    # def click query, element = driver
    # element.find_element(query).click
    # end

    def mobile?
      browser.device.mobile?
    end

    def tablet?
      browser.device.tablet?
    end

    def device
      if tablet?
        "tablet"
      elsif mobile?
        "mobile"
      else
        "desktop"
      end
    end

    def inner_height
      wait_until { driver.find_element(:tag_name, "html") }
        .attribute("clientHeight").to_i
    end

    def wait_until time = 10
      Selenium::WebDriver::Wait.new(timeout: time).until { yield }
    end
  end
end
