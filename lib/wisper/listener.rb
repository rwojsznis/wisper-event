# frozen_string_literal: true

module Wisper
  module Listener
    def self.generated_method_name(event_class)
      class_name = event_class.gsub('::', '_')
      name =
        class_name
          .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
          .gsub(/([a-z\d])([A-Z])/, '\1_\2')
          .downcase

      "on_#{name}"
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    def _wisper_listener?
      true
    end

    module ClassMethods
      def on(event_class, &block)
        method_name = Wisper::Listener.generated_method_name(event_class.name)

        define_method(method_name) do |event|
          instance_exec(event, &block)
        end
      end
    end
  end
end
