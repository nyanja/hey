# frozen_string_literal: true

module Bot
  class Runner
    attr_reader :core, :query

    extend Forwardable
    def_delegators :core, :driver, :config
    # def_delegators :driver, :click

    include Helpers::Logger
    include Helpers::Wait
    include Helpers::Sites
    include Helpers::Queries
    include Helpers::Results

    # include Scenarios::Single

    
  end
end
