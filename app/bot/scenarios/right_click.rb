# frozen_string_literal: true

module Bot
  module Scenarios
    class RightClick < Base
      def initialize *args
        super

        @query, @site, @amount = @query.split("/")
        @links = []
      end

      def perform
        search
        assign_search_results
        search_result
        return log(:error, "Нет подходящего сайта") unless @result

        driver.scroll_to element: @result, behavior: :search

        collect_links

        @user_agent = driver.user_agent
        driver.quit

        perform_visits
      end

      private

      def search_result
        @result = @search_results.find { |r| r.text.match?(Regexp.new(@site)) }
      end

      def collect_links
        @amount.to_i.times do
          driver.action.context_click(@result.find_element(css: "a")).perform
          @links << @result.find_element(css: "a").attribute(:href)
          sleep config.links_harvest_delay
        end
      end

      def perform_visits
        @links.each do |link|
          core.driver = Bot::Driver.new core, user_agent: @user_agent
          perform_single_visit_behavior link
        rescue StandardError
          nil
        ensure
          wait :links_delay
        end
      end
    end
  end
end
