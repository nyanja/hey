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
        visit_click
        wait :pre_delay, behavior: true
        driver.switch_tab 1
      rescue Selenium::WebDriver::Error::TimeOutError
        puts "Страница загружается слишком долго"
      rescue Errors::ThereIsNoSuchWindow
        log(:error,
            "Время ожидания открытия окна (pre_delay) слишком маленькое " \
            "или новое окно не получилось открыть.")
      ensure
        output_spent_time
      end

      def visit_click
        check_time
        driver.click(query: { css: link_css },
                     element: @result)
      rescue Selenium::WebDriver::Error::NoSuchElementError
        raise Errors::NotFound, "Ссылка не была найдена на странице поиска "
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
        if behavior_config(:last_path_link)
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

      def behavior_config name, behavior = @visit_type
        config.send("#{behavior}_#{name}")
      end
    end
  end
end
