# frozen_string_literal: true

module Bot
  module Scenarios
    class Base
      attr_reader :core, :query

      extend Forwardable
      def_delegators :core, :config, :driver

      include Helpers::Results
      include Helpers::Logger
      include Helpers::Wait
      include Helpers::Queries
      include Helpers::Sites

      include Behaviors

      def initialize core, query
        @core = core
        @query = query
      end

      # private

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
