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
      def_delegators :core, :config, :driver

      def initialize core, result, status
        @core = core
        @result = result
        @visit_type = status
      end

      private

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
        driver.scroll_to element: @result, behavior: behavior_name
        sleep 1
        visit_click
        wait behavior_config(:pre_delay)
        # what about depth visits for target and additional_visits for rival
        driver.switch_tab 1
      rescue Selenium::WebDriver::Error::TimeOutError
        puts "stop"
        nil
      ensure
        output_spent_time
      end

      def visit_click
        check_time
        driver.click(query: { css: link_css },
                     element: @result,
                     behavior: behavior_name)
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

      def link_css
        if nehavior_config(:last_path_link)
          return ".organic__path .link:last-of-type"
        end

        ".organic__url, .organic__link, a"
      end

      def start_visit_time_counting
        @start_time = Time.now.to_i
      end

      def rest_of_visit!
        @rest_of_visit = (@start_time + behavior_config(:min_visit)) -
                         Time.now.to_i
      end

      def scroll_percent
        @scroll_percent ||= behavior_config(:scroll_height)
      end

      def behavior_config name, behavior = behavior_name
        config.send("#{behavior}_#{name}")
      end

      def behavior_name
        case @visit_type
        when :pseudo, :main
          :target
        else
          @visit_type
        end
      end
    end
  end
end
