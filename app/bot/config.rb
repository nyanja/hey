module Bot
  module Config
    class << self
      def respond_to_missing?
        true
      end

      def method_missing method, *_args
        if cfg.key? method.to_s
          cfg[method.to_s]

        elsif cfg.key? "#{method}_range"
          rand Range.new(*cfg["#{method}_range"])

        elsif cfg.key? "#{method}_patterns"
          Regexp.new(cfg["#{method}_patterns"].join("|"), "i")

        elsif cfg.key? "#{method}_sample"
          cfg["#{method}_sample"].sample

        elsif cfg.key? "#{method}_chance"
          cfg["#{method}_chance"] > rand(0..100)
        end
      end

      private

      def cfg
        @cfg ||= YAML.load_file("./config.yml")
      end
    end
  end
end
