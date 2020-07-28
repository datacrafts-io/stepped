module Stepped
  module InstanceMethods
    def initialize(*params, **options)
      @definitions = {}

      setup_arguments_defs(self.class.params_defs, params)
      setup_arguments_defs(self.class.options_defs, options)

      logger_instance.on_start(params, options)
    end

    def call
      @result = @args_for_next_step = nil

      if wrapper
        wrapper.call do
          process
        end
      else
        process
      end

      logger_instance.on_end(@result)
      @result
    end

    def process
      steps.each do |name, defs|
        args = args_for_step(name, defs)
        @result = instance_exec(*args, &defs[:block])
      rescue StandardError => e
        @result = handle_error(name, defs, e)
        break if stop_on_failure
      ensure
        @args_for_next_step = defs[:pass] ? @result : nil
        defs[:result] = defs[:cache] ? @result : nil
        logger_instance.after_step(name, @args_for_next_step)
      end
    end

    def step_result(name)
      return if name.nil?

      steps[name.to_sym][:result]
    end

    private

    def args_for_step(step_name, defs)
      args = step_result(defs[:from]) || @args_for_next_step

      logger_instance.before_step(step_name, args)

      args.nil? ? nil : [args]
    end

    def setup_arguments_defs(defs, args)
      defs&.each_with_index do |(def_name, options), index|
        if args.is_a?(Hash)
          value = args[def_name]
          type = :option
        else
          value = args[index]
          type = :param
        end
        value = extract_definition(type, value, def_name, options)

        define_singleton_method(def_name) { value }
      end
    end

    def extract_definition(type, value, name, coercer: nil, default: nil)
      default_value = instance_exec(&default) unless default.nil?

      if value.nil? && default_value.nil?
        raise NotImplementedError, "#{type} \"#{name}\" is not set"
      end

      value = instance_exec(value, &coercer) unless coercer.nil? || value.nil?
      value ||= default_value
      value
    end

    def handle_error(name, options, error)
      error_handler = options[:on_failure] || common_error_handler

      case error_handler
      when Proc
        instance_exec(name, error, &error_handler)
      when Symbol, String
        method(error_handler.to_sym).call(name, error)
      end

      raise error if reraise
    end

    # define instance readers for class methods
    %i[
      steps common_error_handler reraise
      stop_on_failure logger_instance wrapper
    ].each do |method_name|
      define_method(method_name) do |*args|
        self.class.send(method_name, *args)
      end
    end
  end
end
