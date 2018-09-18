module Bot
  class Logger
    def self.method_missing method, text = "", note = nil, *_
      keys = {
        visit: "--- Посещение:",
        target: "    Целевой сайт:",
        non_target: "    Нецелевой сайт:",
        query: "=== Запрос:"
      }
      puts "#{keys.fetch(method, method)} #{text[0..60].tr("\n", ' ')} \
            #{note}"
    end
  end
end
