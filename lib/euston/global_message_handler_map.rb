module Euston
  class GlobalMessageHandlerMap
    def initialize namespaces
      @namespaces = namespaces
      @message_map = {}
    end

    def command_handlers
      handlers = []

      for_all_subscriptions do |subscription|
        handlers << subscription[:handler] unless subscription[:category] == :event_handler
      end

      handlers.uniq
    end

    def event_handlers
      handlers = []

      for_all_subscriptions do |subscription|
        handlers << subscription[:handler] unless subscription[:category] == :command_handler
      end

      handlers.uniq
    end

    def find_message_handlers message
      mapping = @message_map[message[:headers][:type]]
      raise UnroutableMessageError, "No known message handler is capable of handling version #{message[:headers][:version]} of the #{message[:headers][:type]} message." if mapping.nil?
      handlers = mapping[message[:headers][:version]]
      raise UnroutableMessageError, "No known message handler is capable of handling version #{message[:headers][:version]} of the #{message[:headers][:type]} message." if handlers.nil? || handlers.empty?
      handlers
    end

    def inspect_message_handlers
      discover_message_handlers.each do |message_handler|
        klass = message_handler[:klass]
        klass.message_map.verify_message_classes @namespaces.commands, @namespaces.events
        subscriptions = klass.message_map.get_message_subscriptions

        record_subscriptions message_handler[:category], subscriptions[:commands] do |subscription, message_type_map, discovered_version, discovered_message_source|
          if message_type_map.has_key? discovered_version
            conflicting_classes = [message_type_map[discovered_version], discovered_message_source]
            raise SubscriptionRedefinitionError, "The following two command handlers are in conflict over who handles version #{subscription[:version]} of the #{subscription[:type]} command: #{conflicting_classes.join(', ')}"
          end
        end

        record_subscriptions message_handler[:category], subscriptions[:events]
      end
    end

    private

    def for_all_subscriptions
      @message_map.each do |message_type, versions|
        versions.each do |version, subscriptions|
          subscriptions.each do |subscription|
            yield subscription
          end
        end
      end
    end

    def record_subscriptions category, subscriptions
      subscriptions.each do |subscription|
        message_type_map = (@message_map[subscription[:type]] ||= {})
        discovered_version = subscription[:version]
        discovered_message_source = subscription[:message_source]

        yield subscription, message_type_map, discovered_version, discovered_message_source if block_given?

        message_type_map[discovered_version] ||= []
        message_type_map[discovered_version] << { category: category, handler: discovered_message_source }
      end
    end

    def discover_message_handlers
      message_handlers = []

      @namespaces.message_handlers.each do |namespace|
        discovered = namespace.constants.map do |constant|
          klass = namespace.const_get constant
          mixins = klass.included_modules

          category = if mixins.include? Euston::MessageSource
            :message_source
          elsif mixins.include? Euston::CommandHandler
            :command_handler
          elsif mixins.include? Euston::EventHandler
            :event_handler
          else
            nil
          end

          category.nil? ? nil : { category: category, klass: klass }
        end.compact

        message_handlers.push *discovered
      end

      message_handlers
    end
  end
end
