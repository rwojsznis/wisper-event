# frozen_string_literal: true

module WisperEvent
  module Patches
    module BlockRegistration
      def broadcast(event, _publisher, *args, **kwargs)
        return unless should_broadcast?(event)

        if event.is_a?(String) || event.is_a?(Symbol)
          super
        else
          # Structured event
          listener.call(event)
        end
      end
    end
  end
end

Wisper::BlockRegistration.prepend(WisperEvent::Patches::BlockRegistration)
