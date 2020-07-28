module Stepped
  class Logger
    attr_reader :class_name, :config

    def setup(class_name:, **config)
      @class_name = class_name
      @config = config.symbolize_keys
    end

    def on_start(params, options)
      return unless on_start?

      all_arguments = params + Array.wrap(options)

      message = <<~TEXT
        [Stepped] Started #{class_name} with arguments:
        #{format(all_arguments)}
      TEXT

      log(message)
    end

    def before_step(name, received)
      return unless before_step?

      message = <<~TEXT
        [Stepped] Step [#{name}] received:
        #{format(received)}
      TEXT
      log(message)
    end

    def after_step(name, passed)
      return unless after_step?

      message = <<~TEXT
        [Stepped] Step [#{name}] passed:
        #{format(passed)}
      TEXT
      log(message)
    end

    def on_end(result)
      return unless on_end?

      message = <<~TEXT
        [Stepped] #{class_name} finished and returned:
        #{format(result)}
      TEXT

      log(message)
    end

    private

    def log(message)
      config[:method].call(message)
    end

    def format(data)
      data_as_json = data.try(:as_json) || data
      JSON.pretty_generate(data_as_json)
          .split("\n")
          .map { |line| "  | #{line}" }
          .join("\n")
    end

    %i[on_start before_step after_step on_end].each do |name|
      define_method("#{name}?") do
        [true, "true"].include?(config[name])
      end
    end
  end
end
