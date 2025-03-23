# @api private

module Wisper
  class ObjectRegistration < Registration
    attr_reader :with, :prefix, :allowed_classes, :broadcaster

    def initialize(listener, **options)
      super(listener, **options)
      @with = options[:with]
      @prefix = ValueObjects::Prefix.new options[:prefix]
      @allowed_classes = Array(options[:scope]).map(&:to_s).to_set
      @broadcaster = map_broadcaster(options[:async] || options[:broadcaster])
    end

    def broadcast(event, publisher, *args, **kwargs)
      if event.is_a?(String) || event.is_a?(Symbol)
        # Original string/symbol event behavior
        method_to_call = map_event_to_method(event)
        if should_broadcast?(event) && listener.respond_to?(method_to_call) && publisher_in_scope?(publisher)
          broadcaster.broadcast(listener, publisher, method_to_call, *args, **kwargs)
        end
      else
        # Structured event behavior
        method_name = Wisper::Listener.generated_method_name(event.class.name)

        if listener.respond_to?(:_wisper_listener?) && !listener.respond_to?(method_name)
          raise NoMethodError, "listener does not respond handle #{event.class}"
        end

        # raise error if doesn't respond to?
        if publisher_in_scope?(publisher) && listener.respond_to?(method_name)
          broadcaster.broadcast(listener, publisher, method_name, event)
        end
      end
    end

    private

    def publisher_in_scope?(publisher)
      allowed_classes.empty? || publisher.class.ancestors.any? { |ancestor| allowed_classes.include?(ancestor.to_s) }
    end

    def map_event_to_method(event)
      prefix + (with || event).to_s
    end

    def map_broadcaster(value)
      return value if value.respond_to?(:broadcast)
      value = :async if value == true
      value = :default if value == nil
      configuration.broadcasters.fetch(value)
    end

    def configuration
      Wisper.configuration
    end
  end
end
