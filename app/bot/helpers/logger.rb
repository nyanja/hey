# coding: utf-8
# frozen_string_literal: true

module Bot
  module Helpers
    module Logger
      # \e[ m \e[0m
      # 31 red
      # 32 green
      # 33 yellow
      # 34 blue
      # 35 pink
      # 36 light blue

      KEYS = { visit: "\n- \e[36mОбработка\e[0m:",
               main_target: "  \e[32mЦелевой сайт\e[0m:",
               pseudo_target: "  \e[34mДополнительный целевой сайт\e[0m:",
               non_target: "  Нецелевой сайт:",
               query: "\n= \e[33mЗапрос\e[0m:",
               skip: "  Пропуск:",
               skip!: "\n- \e[36mПропуск\e[0m:",
               wait: "  \e[35mПауза\e[0m:",
               error: "  \e[31mОшибка\e[0m:",
               link: "  \e[32mПереход\e[0m:",
               ip: "  \e[33mIP\e[0m:",
               info: "\n  \e[33m>>\e[0m " }.freeze

      def log method, content = nil, note = nil, *___
        text = case content
               when Float
                 content.round(2)
               when String
                 content.to_s[0..60].tr("\n", " ")
               else
                 content
               end
        puts "#{KEYS.fetch(method, method)} #{text} #{note}"
      end
    end
  end
end
