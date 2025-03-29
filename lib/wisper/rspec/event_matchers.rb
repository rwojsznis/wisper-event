# frozen_string_literal: true

module Wisper
  module RSpec
    class EventObjectRecorder
      attr_reader :captured_events

      def initialize
        @captured_events = []
      end

      def respond_to?(_method_name, _include_private = false)
        true
      end

      def respond_to_missing?(*)
        true
      end

      def _wisper_listener?
        true
      end

      def method_missing(_method_name, *args)
        @captured_events << args[0]
      end

      def trigger(event)
        @captured_events << event
      end

      def received_event?(expected_event, expected_attributes = nil)
        @captured_events.any? do |event|
          expected_class = expected_event.is_a?(Class) ? expected_event : expected_event.class

          if event.is_a?(expected_class)
            if expected_attributes.nil?
              expected_event.is_a?(Class) || event == expected_event
            else
              expected_attributes.all? do |key, value|
                event.respond_to?(key) && event.public_send(key) == value
              end
            end
          end
        end
      end
    end

    module BroadcastEventMatcher
      class EventMatcher
        include ::RSpec::Matchers::Composable

        def initialize(event)
          @expected_event = event
          @expected_attributes = nil
          @is_class = event.is_a?(Class)
        end

        def with(attributes)
          @expected_attributes = attributes
          self
        end

        def supports_block_expectations?
          true
        end

        def matches?(block)
          @recorder = EventObjectRecorder.new

          Wisper.subscribe(@recorder) do
            block.call
          end

          @recorder.received_event?(@expected_event, @expected_attributes)
        end

        def description
          desc = + "broadcast event of type #{event_class_name}"
          desc << " with attributes #{@expected_attributes.inspect}" if @expected_attributes
          desc
        end

        def failure_message
          msg = + "expected publisher to broadcast event of type #{event_class_name}"
          msg << " with attributes #{@expected_attributes.inspect}" if @expected_attributes
          msg << captured_events_list
          msg
        end

        def failure_message_when_negated
          msg = + "expected publisher not to broadcast event of type #{event_class_name}"
          msg << " with attributes #{@expected_attributes.inspect}" if @expected_attributes
          msg
        end

        def diffable?
          true
        end

        def expected
          @expected_event
        end

        def actual
          @recorder.captured_events
        end

        private

        def captured_events_list
          if @recorder.captured_events.any?
            events = @recorder.captured_events.map do |event|
              event.is_a?(Array) ? "#{event[0]}(#{event[1..].join(', ')})" : event.inspect
            end
            " (actual events broadcast: #{events.join(', ')})"
          else
            ' (no events broadcast)'
          end
        end

        def event_class_name
          @is_class ? @expected_event.name : @expected_event.class.name
        end
      end

      def broadcast_event(event)
        EventMatcher.new(event)
      end
    end
  end
end

::RSpec::Matchers.define_negated_matcher :not_broadcast_event, :broadcast_event

RSpec.configure do |config|
  config.include Wisper::RSpec::BroadcastEventMatcher
end
