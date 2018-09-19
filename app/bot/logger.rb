module Bot
  class Logger
    def self.method_missing method, content = nil, note = nil, *_

      # \e[ m \e[0m
      # 31 red
      # 32 green
      # 33 yellow
      # 34 blue
      # 35 pink
      # 36 light blue

      keys = {
        visit: "\n--- \e[36mОбработка\e[0m:",
        main_target: "    \e[32mЦелевой сайт\e[0m:",
        pseudo_target: "    \e[34mДополнительный целевой сайт\e[0m:",
        non_target: "    Нецелевой сайт:",
        query: "\n=== \e[33mЗапрос\e[0m:",
        skip: "    Пропуск:",
        skip!: "\n--- \e[36mПропуск\e[0m:",
        wait: "    \e[35mПауза\e[0m:",
        error: "    \e[31mОшибка\e[0m:",
        link: "    \e[32mПереход\e[0m:"
      }

      text = case content
             when Float
               content.round(2)
             when String
               content.to_s[0..60].tr("\n", " ")
             else
               content
             end

      puts "#{keys.fetch(method, method)} #{text} #{note}"
    end
  end
end
