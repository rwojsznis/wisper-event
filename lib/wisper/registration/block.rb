# @api private

module Wisper
  class BlockRegistration < Registration
    def broadcast(event, publisher, *args, **kwargs)
      if should_broadcast?(event)
        if event.is_a?(String) || event.is_a?(Symbol)
          # Original string/symbol event behavior
          listener.call(*args, **kwargs)
        else
          # Structured event behavior
          listener.call(event)
        end
      end
    end
  end
end
