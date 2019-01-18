# frozen_string_literal: true

module Bot
  module Behaviors
    class Base
      attr_reader :core, :result, :visit_type

      include Helpers::Logger
      include Helpers::Wait
      include Helpers::Sites
      include Helpers::Results # temporary... will hope=)

      extend Forwardable
      def_delegator :core, :config, :driver

      def initialize core, result, status
        @core = core
        @result = result
        @visit_type = status
      end

      def unique_ip?
        return true unless config.unique_visit_ip?

        d = domain(@result)
        if Ip.current == Storage.get(d)
          log(:info, "#{d}: Посещение с таким IP уже было")
          false
        else
          Storage.set(d, Ip.current)
          true
        end
      end

      def visit
        # REPLACE
        # driver.scroll_to [(result.location.y - rand(140..300)), 0].max
        sleep 1
        visit_click
        wait pre_delay if pre_delay&.positive? # why this check not in wait???
        driver.switch_tab 1
      rescue Selenium::WebDriver::Error::TimeOutError
        puts "stop"
        nil
      ensure
        output_spent_time
      end

      def visit_click
        check_time
        # REPLACE
        # driver.click(query: { css: link_css },
        #              element: @result)
      rescue Selenium::WebDriver::Error::NoSuchElementError
        puts "element not found"
      end

      def check_time
        @t = Time.now
      end

      def output_spent_time
        return unless @t

        log :info, "Время: #{Time.now - @t}\n"
        @t = nil
      end

      # def visit
      # super(@result, pre_delay, link_css)
      # end

      def link_css
        return ".organic__path .link:last-of-type" if last_path_link?

        ".organic__url, .organic__link, a"
      end

      def start_visit_time_counting
        @start_time = Time.now.to_i
      end

      def rest_of_visit!
        @rest_of_visit = (@start_time + min_visit) - Time.now.to_i
      end
    end
  end
end
