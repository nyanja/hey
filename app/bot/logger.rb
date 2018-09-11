module Bot
  class Logger
    def self.method_missing method, text, *_
      puts "#{method} \"#{text[0..60].tr("\n", ' ')}...\""
    end
  end
end
