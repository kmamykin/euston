module Euston
  class MessageHandlerMessageMap
    def initialize event_source_class
      @event_source = event_source_class

      @map = { initialization:  nil,
               commands:        {},
               events:          {},
               snapshots:       {},
               transitions:     {} }
    end

    def define section_name, message_name, args, &block
      section = @map[section_name]
      section[message_name] = {} unless section.key? message_name
      message = section[message_name]
      identifier, version = :id, 1

      while arg = args.shift
        version = arg if arg.is_a? Integer
        identifier = arg if arg.is_a? Symbol
      end

      if message.key? version
        raise SubscriptionRedefinitionError, "Attempt made to redefine version #{version} of #{section.to_s.chop} :#{message_name} in event source #{@event_source}"
      end

      method_name = method_name_for_message message_name, version
      message_type = section_name == :commands ? :command : :event
      message_class = MessageClassFinder.get_class_name message_name, version
      message[version] = { method: method_name, message_type: message_type, message_class: message_class }
      message[version][:identifier] = identifier unless section_name == :transitions

      @message_defined_callback.call method_name, block
    end

    def define_initializer &block
      unless @map[:initialization].nil?
        raise InitializationRedefinitionError, "Attempt made to redefine the initialization block in event source #{@event_source}"
      end

      @map[:initialization] = :defined

      @initializer_defined_callback.call :initialization, block
    end

    def define_snapshot action, args, &block
      args << 1
      version = args.shift
      section = @map[:snapshots]
      section[version] = {} unless section.has_key? version
      metadata = section[version]

      if metadata.has_key? action
        raise SnapshotRedefinitionError, "Attempt made to redefine version #{version} of the snapshot :#{action} action in event source #{@event_source_class}"
      end

      method_name = method_name_for_snapshot action, version
      metadata[action] = method_name

      @snapshot_defined_callback.call method_name, block
    end

    def get_message_subscriptions
      subscriptions = { commands: [], events: [] }

      [:commands, :events].each do |subscription_type|
        @map[subscription_type].each do |type, versions|
          versions.each do |version, metadata|
            subscriptions[subscription_type] << { event_source: @event_source,
                                                  type:         type,
                                                  version:      version }
          end
        end
      end

      subscriptions
    end

    def get_mapping_for_message message
      message_type = message[:headers][:type]
      mapping = @map[:commands][message_type] || @map[:events][message_type]
      return mapping[message[:headers][:version]] unless mapping.nil?
    end

    def get_method_name_for_message *args
      if args.length == 1
        hash = args[0].is_a?(Hash) ? args[0] : args[0].to_hash
        headers = hash[:headers]
        message_type, message_version = headers[:type], headers[:version]
      else
        message_type, message_version = args
      end

      metadata = @map[:commands][message_type]
      metadata = @map[:events][message_type] if metadata.nil?
      metadata = @map[:transitions][message_type] if metadata.nil?

      raise_not_found_error message_type, message_version if metadata.nil?

      metadata = metadata[message_version]

      raise_not_found_error message_type, message_version if metadata.nil?

      method_name_for_message(message_type, message_version).to_sym
    end

    def get_method_name_to_load_snapshot snapshot
      method_name_for_snapshot :load_from, snapshot.version
    end

    def get_newest_snapshot_metadata
      versions = @map[:snapshots].keys

      if versions.empty?
        raise UnknownSnapshotError, "Attempt to take snapshot when no snapshot methods are defined on event source #{@event_source}."
      end

      version = versions.sort.pop

      { method_name: method_name_for_snapshot(:save_to, version), version: version }
    end

    def verify_message_classes command_namespaces, event_namespaces
      [{ section: :commands,    namespaces: command_namespaces },
       { section: :events,      namespaces: event_namespaces },
       { section: :transitions, namespaces: event_namespaces }].each do |category|
        @map[category[:section]].each do |type, versions|
          versions.each do |version, metadata|
            found = category[:namespaces].any? do |namespace|
              namespace.const_defined? metadata[:message_class]
            end

            unless found
              raise UnverifiableEventSource, "Failed to find version #{version} of the #{type} #{category[:section].to_s.singularize} referred to in message handler #{@event_source}."
            end
          end
        end
      end
    end

    def has_initializer?
      !@map[:initialization].nil?
    end

    def initializer_defined &block
      @initializer_defined_callback = block
    end

    def message_defined &block
      @message_defined_callback = block
    end

    def snapshot_defined &block
      @snapshot_defined_callback = block
    end

    def snapshot_method? method
      [:load_from, :save_to].include? method
    end

    def to_hash
      @map
    end

    private

    def method_name_for_message message_type, message_version
      "#{message_type}_v#{message_version}"
    end

    def method_name_for_snapshot snapshot_action, snapshot_version
      "#{snapshot_action}_v#{snapshot_version}_snapshot"
    end

    def raise_not_found_error message_type, message_version
      raise UnknownMessageError, "Event source #{@event_source} does not know this message: #{message_type} v#{message_version}."
    end
  end
end
