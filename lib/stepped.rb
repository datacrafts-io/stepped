require "stepped/logger"

module Stepped
  require "stepped/class_methods"
  require "stepped/instance_methods"

  def self.included(receiver)
    receiver.extend ClassMethods
    receiver.send :include, InstanceMethods
    receiver.send :set_default_variables
  end
end
