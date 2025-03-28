# frozen_string_literal: true

module WisperEvent
  module Patches
    module Events
      def include?(event)
        if event.is_a?(String) || event.is_a?(Symbol)
          super
        # Structured event
        elsif list.is_a?(Class)
          event.is_a?(list)
        elsif list.is_a?(Enumerable) && list.any? { |item| item.is_a?(Class) }
          list.any? { |item| item.is_a?(Class) && event.is_a?(item) }
        else
          super
        end
      end

      private

      def methods
        {
          NilClass => ->(_event) { true },
          String => ->(event) { list == event },
          Symbol => ->(event) { list.to_s == event },
          Enumerable => ->(event) { list.map(&:to_s).include? event },
          Regexp => ->(event) { list.match(event) || false },
          Class => ->(event) { event.is_a?(list) }
        }
      end
    end
  end
end

Wisper::ValueObjects::Events.prepend(WisperEvent::Patches::Events)
