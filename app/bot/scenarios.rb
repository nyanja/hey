# frozen_string_literal: true

# Представляет собой модуль для обработки запросов
# - искать по запросу или просто перейти по ссылке
# - что делать с результатами поиска
# - какое поведение применить к результату
# Для работы нужны методы `core` && `query`

require_relative "scenarios/base"
require_relative "scenarios/lite"
require_relative "scenarios/right_click"
require_relative "scenarios/default"

module Bot
  module Scenarios
    include Helpers::Queries

    def select_scenario
      case query
      when %r{^https?:\/\/}
        Behaviors.perform_single_visit_bahevior(core, link)
        wait(:query_delay)
        return
      when %r{\/}
        right_clicks_scenario
        wait(:query_delay)
        return
      end

      return if query_delayed? ||
                query_limited?

      default_scenario
    end

    # Поисковый запрос -> парсинг результатов -> lite_behavior
    def lite_scenario
      Lite.new(core, query)
    end

    # Поисковый запрос -> поиск нужного результата по регекспу ->
    # сбор ссылок -> single_visit_behavior for each link
    def right_clicks_scenario
      RightClick.new(core, query)
    end

    # Поисковый запрос -> парсинг результатов ->
    # применение различного `_behavior` для результатов
    # в зависимости от конфигов
    def default_scenario
      Default.new(core, query)
    end
  end
end
