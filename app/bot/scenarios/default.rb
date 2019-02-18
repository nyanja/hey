# frozen_string_literal: true

module Bot
  module Scenarios
    class Default < Base
      def perform
        search
        parse_results && process_query
        driver.quit
        wait(:query_delay)
      rescue Selenium::WebDriver::Error::NoSuchElementError => e
        log(:error, "Нетипичная страница поиска")
        puts e.inspect
        driver.quit
      end

      private

      def process_query
        count_this_query
        @verified_results.each { |r| parse_result(*r) }
        :pass
      end

      # element, [:skip, :rival, :pseudo, :target].sample, position_index
      def parse_result result, status, index
        log(:visit, "##{index + 1} #{domain(result)}", "[#{driver&.device}]")

        if status == :skip
          log(:skip, "Пропуск сайта")
        else
          parse_result_page(result, status)
        end

        # puts "Delay: #{config.result_delay}"
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
        puts
        log :error, "Необрабатываемая страница"
      rescue Selenium::WebDriver::Error::NoSuchWindowError
        puts
        log :error, "Окно было закрыто"
      rescue Selenium::WebDriver::Error::UnknownError => e
        log :error, e.inspect
      rescue StandardError => e
        puts
        log :error, "Ошибка на странице результата", e.inspect
        puts e.backtrace
      ensure
        driver&.close_tab
      end
    end
  end
end
