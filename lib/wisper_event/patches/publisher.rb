# frozen_string_literal: true

module WisperEvent
  module Patches
    module Publisher
      def broadcast(event, *args, **kwargs)
        registrations.each do |registration|
          if event.is_a?(String) || event.is_a?(Symbol)
            registration.broadcast(clean_event(event), self, *args, **kwargs)
          else
            # Structured event - pass them directly
            registration.broadcast(event, self, *args, **kwargs)
          end
        end
        self
      end
    end
  end
end

Wisper::Publisher.prepend(WisperEvent::Patches::Publisher)
