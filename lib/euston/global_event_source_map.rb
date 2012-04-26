module Euston
  class GlobalEventSourceMap
    def initialize namespaces
      @namespaces = namespaces
      @command_map = {}
    end

    def find_command_handler command
      mapping = @command_map[command[:headers][:type]]
      raise UnroutableMessageError, "No known event source is capable of handling version #{command[:headers][:version]} of the #{command[:headers][:type]} command." if mapping.nil?
      klass = mapping[command[:headers][:version]]
      raise UnroutableMessageError, "No known event source is capable of handling version #{command[:headers][:version]} of the #{command[:headers][:type]} command." if klass.nil?
      klass
    end

    def inspect_event_sources
      event_sources = discover_event_sources

      event_sources.each do |event_source|
        event_source.message_map.verify_message_classes @namespaces.commands, @namespaces.events

        event_source.message_map.get_command_subscriptions.each do |subscription|
          @command_map[subscription[:type]] = {} unless @command_map.has_key? subscription[:type]

          command_type_map = @command_map[subscription[:type]]
          discovered_version = subscription[:version]
          discovered_event_source = subscription[:event_source]

          if command_type_map.has_key? discovered_version
            conflicting_classes = [command_type_map[discovered_version], discovered_event_source]
            raise SubscriptionRedefinitionError, "The following two event sources are in conflict over who handles version #{subscription[:version]} of the #{subscription[:type]} command: #{conflicting_classes.join(', ')}"
          end

          command_type_map[discovered_version] = discovered_event_source
        end
      end
    end

    private

    def discover_event_sources
      event_sources = []

      @namespaces.event_sources.each do |namespace|
        discovered = namespace.constants.map do |constant|
          klass = namespace.const_get constant

          if klass.included_modules.include? Euston::EventSource
            klass
          else
            nil
          end
        end.compact

        event_sources.push *discovered
      end

      event_sources.uniq
    end
  end
end
