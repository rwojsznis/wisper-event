# frozen_string_literal: true

module WisperEvent
  module Patches
    module BlockRegistration
      def broadcast(event, _publisher, *args, **kwargs)
        return unless should_broadcast?(event)

        if event.is_a?(String) || event.is_a?(Symbol)
          super
        else
          listener.call(event) # Structured event behavior
        end
      end
    end
  end
end

Wisper::BlockRegistration.prepend(WisperEvent::Patches::BlockRegistration)
