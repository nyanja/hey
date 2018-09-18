module Bot
  class Logger
    def self.method_missing method, text = "", note = nil, *_

      # \e[ m \e[0m
      # 31 red
      # 32 green
      # 33 yellow
      # 34 blue
      # 35 pink
      # 36 light blue

      keys = {
        visit: "--- \e[36mОбработка\e[0m:",
        target: "    \e[32mЦелевой сайт\e[0m:",
        non_target: "    Нецелевой сайт:",
        query: "=== \e[33mЗапрос\e[0m:",
        skip: "    Пропуск:",
        wait: "    \e[35mПауза\e[0m:",
        error: "    \e[31mОшибка\e[0m:"
      }
      puts "#{keys.fetch(method, method)} #{text.to_s[0..60].tr("\n", ' ')} \
            #{note}"
    end
  end
end
