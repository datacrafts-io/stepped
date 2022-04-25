module Stepped
  module ClassMethods
    attr_reader :steps, :common_error_handler, :reraise, :stop_on_failure,
                :params_defs, :options_defs, :logger_instance,
                :wrapper, :wrap_only

    def call(*params, **options)
      new(*params, **options).call
    end

    private

    def set_default_variables
      @common_error_handler = ->(e) {}
      @reraise = true
      @stop_on_failure = false
      @steps = {}
      @logger_instance = Stepped::Logger.new
    end

    def param(name, coercer = nil, default: nil)
      @params_defs ||= {}
      @params_defs[name.to_sym] = { coercer: coercer, default: default }
    end

    def option(name, coercer = nil, default: nil)
      @options_defs ||= {}
      @options_defs[name.to_sym] = { coercer: coercer, default: default }
    end

    # Possible options is
    #   - pass (default: true): pass result of this step to next step
    #   - cache (default: false): cache the result of this step
    #   - from: name of step which result must be passed to
    #           current step (`from` step should be `cache: true`)
    #   - on_failure (first arg is step name, second arg is exception):
    #     * Proc
    #     * name of method
    def step(name, pass: true, cache: false, **kwargs, &block)
      @steps[name.to_sym] = {
        block: block,
        pass: pass,
        cache: cache,
        **kwargs
      }
    end

    # - handler: Common error handler for all steps could be:
    #   * Proc
    #   * name of instance method
    #   => must receive 2 arguments (name, error)
    # - reraise (default: true): reraise exception after handler call
    def on_failure(handler = nil, stop: false, reraise: true)
      @common_error_handler = handler unless handler.nil?
      @reraise = reraise
      @stop_on_failure = stop
    end

    def wrap(wrapper, only: [])
      @wrapper = wrapper
      @wrap_only = only
    end

    def logger(on_start: false,
               before_step: false,
               after_step: false,
               on_end: false,
               method: nil)
      @logger_instance.setup(
        class_name: name,
        on_start: on_start,
        before_step: before_step,
        after_step: after_step,
        on_end: on_end,
        method: method
      )
    end
  end
end
