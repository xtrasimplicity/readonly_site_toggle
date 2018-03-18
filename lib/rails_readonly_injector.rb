require "rails_readonly_injector/version"
require "rails_readonly_injector/configuration"

module RailsReadonlyInjector
  def self.reload!
    config.classes_to_include.each do |klass|
    
      # Ensure we don't impact classes that we want to exclude
      if config.classes_to_exclude.include? klass
        restore_readonly_method(klass)
        next
      end

      if self.config.read_only
        override_readonly_method(klass)
      else
        restore_readonly_method(klass)
      end
    end

    inject_error_handler_into_actioncontroller_base
  end

  private

  ALIASED_METHOD_NAME = :old_readonly?

  def self.override_readonly_method(klass)
    klass.class_eval do
      alias_method ALIASED_METHOD_NAME, :readonly?

      def readonly?
        true
      end
    end
  end

  def self.restore_readonly_method(klass)
    klass.class_eval do
      def readonly?
        super
      end
    end
  end

  def self.inject_error_handler_into_actioncontroller_base
    ActionController::Base.class_eval do |klass|
      rescue_from ActiveRecord::ReadOnlyRecord, with: :rescue_from_readonly_failure

      protected

      def rescue_from_readonly_failure
        instance_eval &RailsReadonlyInjector.config.controller_rescue_action
      end
    end
  end
end
