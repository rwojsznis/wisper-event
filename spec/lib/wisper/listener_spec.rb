# frozen_string_literal: true

require 'spec_helper'
require 'wisper/listener'

RSpec.describe Wisper::Listener do
  # Test event classes
  class SimpleEvent; end

  module Namespace
    class NestedEvent; end
  end

  class CamelCaseEventName; end

  describe '.generated_method_name' do
    it 'converts simple class name to snake_case method name with on_ prefix' do
      expect(described_class.generated_method_name('SimpleEvent')).to eq('on_simple_event')
    end

    it 'converts namespaced class to method name with namespaces as underscores' do
      expect(described_class.generated_method_name('Namespace::NestedEvent')).to eq('on_namespace_nested_event')
    end

    it 'works for deeply nested namespaces' do
      expect(described_class.generated_method_name('Namespace::Deeply::Nested::Event')).to eq('on_namespace_deeply_nested_event')
    end

    it 'properly handles camel case conversion to snake case' do
      expect(described_class.generated_method_name('CamelCaseEventName')).to eq('on_camel_case_event_name')
    end
  end

  describe '#_wisper_listener?' do
    it 'returns true' do
      listener_class = Class.new { include Wisper::Listener }
      expect(listener_class.new._wisper_listener?).to be(true)
    end
  end

  describe '#trigger' do
    it 'calls the correctly named method when it exists' do
      listener_class = Class.new do
        include Wisper::Listener
        attr_reader :called_with

        def on_simple_event(event)
          @called_with = event
        end
      end

      listener = listener_class.new
      event = SimpleEvent.new

      listener.trigger(event)
      expect(listener.called_with).to eq(event)
    end

    it 'raises UnhandledEventError when method does not exist' do
      listener_class = Class.new { include Wisper::Listener }
      listener = listener_class.new
      event = SimpleEvent.new

      expect do
        listener.trigger(event)
      end.to raise_error(
        Wisper::Listener::UnhandledEventError,
        "Event SimpleEvent not handled in #{listener_class}"
      )
    end
  end

  describe '.on' do
    it 'dynamically defines a method with the correct name' do
      listener_class = Class.new do
        include Wisper::Listener

        on SimpleEvent do |event|
          @received_event = event
        end

        attr_reader :received_event
      end

      listener = listener_class.new
      event = SimpleEvent.new

      expect(listener).to respond_to(:on_simple_event)
      listener.on_simple_event(event)
      expect(listener.received_event).to eq(event)
    end

    it 'allows handling namespaced events' do
      listener_class = Class.new do
        include Wisper::Listener

        on Namespace::NestedEvent do |event|
          @nested_event = event
        end

        attr_reader :nested_event
      end

      listener = listener_class.new
      event = Namespace::NestedEvent.new

      expect(listener).to respond_to(:on_namespace_nested_event)
      listener.on_namespace_nested_event(event)
      expect(listener.nested_event).to eq(event)
    end

    it 'executes the block in the instance context' do
      listener_class = Class.new do
        include Wisper::Listener

        attr_accessor :instance_value

        def initialize
          @instance_value = 'instance_data'
        end

        on SimpleEvent do |event|
          @result = "processed #{event.class} with #{@instance_value}"
        end

        attr_reader :result
      end

      listener = listener_class.new
      event = SimpleEvent.new

      listener.on_simple_event(event)
      expect(listener.result).to eq('processed SimpleEvent with instance_data')
    end
  end
end
