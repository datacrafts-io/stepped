![Ruby](https://github.com/datacrafts-io/stepped/workflows/Ruby/badge.svg?branch=master)

# Make your services Stepped

## Installation

add to your Gemfile:
```ruby
gem "stepped", github: "datacrafts-io/stepped"
```

## Usage

#### 1. `include Stepped` into your service
```ruby
class ClassName
  include Stepped

  ...
end
```

#### 2. Use `param` and `option` keywords to define initial arguments:
```ruby
  class ClassName
    ...

    param :argument_name,               # reader name
          ->(value) { value.to_s },     # optional proc for type coercing
          default: -> { "some string" } # optional proc with default value

    ...
  end
```
`param` is used to define arguments, `option` is for keyword arguments

#### 3. Define the Steps:
- passed params and options are accessed in step blocks
- by default steps are passing result to next step
- set optional `pass: false` to cancel passing result of current step to next
- set optional `cache: true` to save result of current step and access it in another steps later via `step_result(:step_name)`
- set optional `from: :step_name` to receive arguments from `:step_name` instead of previous step (must be combined with `cache: true` for `from` step)
- set optional error handler on step `on_failure: [handler]`, `[handler]` is `Proc` or `:method_name` receiving 2 arguments: `:step_name` and `error` instance
```ruby
  class ClassName
    ...

    step :step_one, cache: true do
      puts "I'm the step one"
      "Result of Step One"
    end

    step :step_two, on_failure: ->(_, err) { ... } do |result_of_prev_step|
      puts result_of_prev_step # => Result of Step One
    end

    step :step_three, from: :step_one do |result_of_step_one|
      puts result_of_prev_step # => Result of Step One
    end

    ...
  end
```


#### 4. Set optional `on_failure` options (default: `on_failure stop: false, reraise: true`):

First optional argument can be `:method_name` or `Proc`:
```ruby
  class ClassName
    ...

    on_failure :error_handler, stop: true,   # stop process on error
                               reraise: true # reraise error after error handling

    def error_handler(step_name, error)
      Notifier.call(step_name, error.message)
    end

    ...
  end
```

#### 5. Use optional logger settings for debug or logging:
```ruby
  class ClassName
    ...

    logger on_start: true,    # => [Stepped] Started ClassName with arguments: (arguments below)
           before_step: true, # => [Stepped] Step [step_name] received: (arguments below)
           after_step: true,  # => [Stepped] Step [step_name] passed: (arguments below)
           on_end: true,      # => [Stepped] ClassName finished and returned: (arguments below)
           method: Rails.logger.method(:info) # method, proc, service, etc which has method :call with one arg

    ...
  end
```

#### 6. Add optional wrapper:
Wrap all steps in block provided by passed arg

```ruby
class ClassName
  ...

  wrap ActiveRecord::Base.method(:transaction) # pass something which has method :call and can receive block

  ...
end
```

## Example usage:

```ruby
  # define class
  class CreateUser
    include Stepped

    param :attributes
    option :available_points, proc(&:to_i), default: -> { 0 }

    on_failure :notify

    step :create_user, cache: true do
      User.create!(attributes)
    end

    step :send_email do |user|
      UserMailer.send_welcome_email(user)
    end

    step :assign_points, from: :create_user do |user|
      user.add_points(available_points)
      user
    end

    step :notify do |user|
      SlackNotifier.user_created(user)
    end

    private

    def notify(step_name, error)
      SlackNotifier.user_create_error(error)
    end
  end

  # use
  attributes = { name: "John", email: "john@example.com" }

  service = CreateUser.new(attributes, available_points: 5)
  service.call

  # or shortly

  CreateUser.call(attributes, available_points: 5)
```
