# frozen_string_literal: true

module WisperEvent
  module Patches
    module ObjectRegistration
      def broadcast(event, publisher, *args, **kwargs)
        # Original string/symbol event behavior
        if event.is_a?(String) || event.is_a?(Symbol)
          super
        # Structured event behavior
        # Wisper::Listeners are required to handle structured events
        elsif listener.respond_to?(:_wisper_listener?)
          listener.trigger(event)
          # as method names for events are auto generated
          # we might as well discard structured events for non-structured listeners
        end
      end
    end
  end
end

Wisper::ObjectRegistration.prepend(WisperEvent::Patches::ObjectRegistration)
