# frozen_string_literal: true

module Bot
  module Scenarios
    class Base
      attr_reader :core, :query

      extend Forwardable
      def_delegator :core, :config, :driver

      include Helpers::Results
      include Helpers::Logger
      include Helpers::Wait
      include Helpers::Queries

      include Behaviors

      def initialize core, query
        @core = core
        @query = query
      end

      private

      # element, [:skip, :rival, :pseudo, :main], position_index
      def parse_result result, status, index
        log(:visit, "##{index + 1} #{domain(result)}", "[#{driver&.device}]")

        if status == :skip
          log(:skip, "Пропуск сайта")
        else
          parse_result_page(result, status)
        end

        wait(:result_delay)
      rescue Selenium::WebDriver::Error::StaleElementReferenceError
        log :error, "Страница неактуальна"
        wait 4
      end

      def parse_result_page result, status
        if status == :rival || (!status && !config.non_target)
          apply_rival_behavior result, status
        elsif status
          apply_target_behavior result, status
        else
          log :skip, "Нейтральный сайт"
        end
      rescue Selenium::WebDriver::Error::NoSuchElementError => e
        puts e.inspect
        log :skip, "Нетипичная ссылка"
      rescue Net::ReadTimeout
        # puts
        log :error, "Необрабатываемая страница"
      rescue Selenium::WebDriver::Error::NoSuchWindowError
        # puts
        log :error, "Окно было закрыто"
      rescue Selenium::WebDriver::Error::UnknownError
        log :error, e.inspect
      rescue HTTP::ConnectionError => e
        raise e
      rescue StandardError => e
        # puts
        log :error, "Ошибка на странице результата", e.inspect
        puts e.backtrace
      ensure
        driver&.close_tab
      end

      # def scroll _is_target = nil
      #   scroll_amount = is_target ? config.scroll_amount_target : config.scroll_amount
      #   amount = if config.scroll_threshold &.< driver.scroll_height
      #              scroll_amount * config.scroll_multiplier
      #            else
      #              scroll_amount
      #            end
      #   driver.scroll_by amount, is_target
      #   print "."
      #   sleep is_target ? config.scroll_delay_target : config.scroll_delay
      # rescue Selenium::WebDriver::Error::TimeOutError
      #   print "x"
      # end
    end
  end
end
