# wisper-event

A structured event extension for the Wisper gem.

## Why wisper-event?

The [Wisper gem](https://github.com/krisleech/wisper) is a popular micro-library for implementing the publisher-subscriber pattern in Ruby. While powerful and flexible, Wisper's approach of broadcasting symbols or strings with unstructured arguments can lead to:

1. **Too loose coupling** - While loose coupling is generally desirable, Wisper's string/symbol-based events make it difficult to track relationships between publishers and subscribers as applications grow
2. **Unclear interfaces** - Without structured events, argument signatures can change unexpectedly, causing silent failures
3. **Poor discoverability** - It's challenging to find all handlers for a specific event across a large codebase

**wisper-event** provides a more structured approach by allowing you to use proper Ruby objects as events while maintaining backward compatibility with Wisper's string/symbol-based events. This lets you:

- Gradually migrate your codebase to structured events
- Have clear, well-defined event interfaces
- Implement compile-time checking of event handlers
- Easily find event usage with standard code search tools

This gem was inspired by the original Wisper author's other gems:
- [wisper_next](https://gitlab.com/kris.leech/wisper_next)
- [ma](https://gitlab.com/kris.leech/ma)

It solves very particular problem and might be not a good fit for your application.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'wisper-event'
```

And then execute:

```
bundle install
```

## Usage

### Enabling wisper-event

After installing the gem, you need to apply the monkey patches:

```ruby
WisperEvent.apply!
```

This is best done during your application's initialization.

### Creating structured events

Define your events as plain Ruby classes:

```ruby
module Event
  class OrderCreated
    attr_reader :order_id, :customer_id
    
    def initialize(order_id:, customer_id:)
      @order_id = order_id
      @customer_id = customer_id
    end
  end

  class OrderFailed
    attr_reader :reason
    
    def initialize(reason)
      @reason = reason
    end
  end
end
```

### Publishing events

You can publish both traditional Wisper events and structured events from the same publisher:

```ruby
class OrderService
  include Wisper::Publisher
  
  def create(params)
    # Business logic...
    if order.save
      # Traditional event with arguments
      broadcast('order_created', order_id: order.id, customer_id: order.customer_id)
      
      # Structured event
      broadcast(Event::OrderCreated.new(order_id: order.id, customer_id: order.customer_id))
    else
      # Traditional event
      broadcast('order_failed', order.errors.full_messages.join(", "))
      
      # Structured event
      broadcast(Event::OrderFailed.new(order.errors.full_messages.join(", ")))
    end
  end
end
```

### Handling events - traditional approach

The traditional Wisper approach still works:

```ruby
class OrderNotifier
  def order_created(order_id:, customer_id:)
    # Handle the event...
  end
  
  def order_failed(reason)
    # Handle the failure...
  end
end

service = OrderService.new
service.subscribe(OrderNotifier.new)
service.create(params)
```

### Handling events - structured approach

To handle structured events, include the `Wisper::Listener` module and define your handlers using the `on` class method:

```ruby
lass StructuredOrderHandler
  include Wisper::Listener
  
  def initialize(logger)
    @logger = logger
  end
  
  on(Event::OrderCreated) do |event|
    @logger.info("Order #{event.order_id} was created for customer #{event.customer_id}")
  end
  
  on(Event::OrderFailed) do |event|
    @logger.error("Order creation failed: #{event.reason}")
  end
end

service = OrderService.new
service.subscribe(StructuredOrderHandler.new(logger))
service.create(params)
```

### Subscribing with Blocks

You can also subscribe to structured events using blocks:

```ruby
service = OrderService.new
service.on(Event::OrderCreated) { |event| puts "Order created: #{event.order_id}" }
       .on(Event::OrderFailed) { |event| puts "Order failed: #{event.reason}" }
service.create(params)
```

## Required event handling

When using `Wisper::Listener`, every structured event **must have** a corresponding handler. If an event is received that the listener doesn't handle, a `Wisper::Listener::UnhandledEventError` will be raised:

```ruby
class IncompleteListener
  include Wisper::Listener
  
  on(Event::OrderCreated) do |event|
    # This handles Event::OrderCreated
  end
  
  # Missing handler for Event::OrderFailed!
end

# This will raise UnhandledEventError when Event::OrderFailed is broadcast
```

This helps ensure that your listeners are complete and don't silently ignore events.

## Testing

The gem includes RSpec matchers build on top of [wisper-rspec](https://github.com/krisleech/wisper-rspec) for testing broadcasted events:

```ruby
# Add this to your spec helper
require 'wisper/rspec/matchers'
require 'wisper/rspec/event_matchers'

RSpec.configure do |config|
  config.include(Wisper::RSpec::BroadcastMatcher)
  config.include(Wisper::RSpec::BroadcastEventMatcher)
end

# In your specs
it 'broadcasts the proper event' do
  service = OrderService.new
  
  expect { service.create(valid_params) }
    .to broadcast_event(Event::OrderCreated).with(order_id: 123, customer_id: 456)
  
  expect { service.create(invalid_params) }
    .to broadcast_event(Event::OrderFailed).with(message: "Invalid params")
end
```

## Migrating to structured events

Here's a migration strategy:

1. Start by creating structured events that match your existing string/symbol events
1. Update your publishers to broadcast both formats
1. Create structured listeners for new code
1. Gradually convert existing listeners to the structured format
1. Once all listeners are updated to use structured events, you can remove the old string/symbol style broadcasts

### Example migration

Before:

```ruby
# Publisher
class OrderService
  include Wisper::Publisher
  
  def create(params)
    if order.save
      broadcast('order_created', order_id: order.id)
    else
      broadcast('order_failed', reason: order.errors.full_messages)
    end
  end
end

# Listener
class OrderNotifier
  def order_created(order_id:)
    # Handle event
  end
  
  def order_failed(reason:)
    # Handle failure
  end
end
```

After

```ruby
# Events
module Event
  class OrderCreated
    attr_reader :order_id
    
    def initialize(order_id:)
      @order_id = order_id
    end
  end

  class OrderFailed
    attr_reader :reason
    
    def initialize(reason:)
      @reason = reason
    end
  end
end

# Publisher (during migration)
class OrderService
  include Wisper::Publisher
  
  def create(params)
    if order.save
      # You can remove this line once all listeners are updated
      broadcast('order_created', order_id: order.id)
      broadcast(Event::OrderCreated.new(order_id: order.id))
    else
      # You can remove this line once all listeners are updated
      broadcast('order_failed', reason: order.errors.full_messages)
      broadcast(Event::OrderFailed.new(reason: order.errors.full_messages))
    end
  end
end

# Modified structured listener
class OrderNotifier
  include Wisper::Listener
  
  on(Event::OrderCreated) do |event|
    # Handle event
  end
  
  on(Event::OrderFailed) do |event|
    # Handle failure
  end

  # If listener is being re-used across different publishers you will be
  # forced to broadcast structured events across those publishers and handle
  # all those events in this listener - which is _desired_ behavior
end
```

## Limitations and assumptions

- This gem focuses on improving event structure, not on Wisper's delivery mechanisms
- Global listeners are not supported with structured events
- Asynchronous event handling is not directly supported - if you need to trigger async jobs, do so explicitly in your listeners
- Every structured event must be handled by listeners that include `Wisper::Listener`
- `on` / `with` events mapping is not supported as it makes no sense with structured events
