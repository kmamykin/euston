module Euston
  module AggregateRoot
    extend ActiveSupport::Concern
    include Euston::AggregateRootPrivateMethodNames
    include Euston::AggregateRootDslMethods
    include Euston::EventHandler

    module ClassMethods
      def hydrate stream, snapshot = nil, log = nil
        instance = self.new
        instance.log = log unless log.nil?
        instance.send :apply_snapshot, snapshot unless snapshot.nil?
        instance.send :apply_stream, stream
        instance
      end
    end

    module InstanceMethods
      def initialize aggregate_id = nil
        @aggregate_id = aggregate_id
        @log = Euston::NullLogger.instance
      end

      attr_accessor :log
      attr_reader :aggregate_id, :stream

      def initial_version
        @initial_version ||= 0
      end

      def has_uncommitted_changes?
        !uncommitted_events.empty?
      end

      def committed_messages
        @committed_messages ||= Set.new
      end

      def uncommitted_commands
        @uncommitted_commands ||= []
      end

      def uncommitted_events
        @uncommitted_events ||= []
      end

      def uncommitted_headers
        @uncommitted_headers ||= {}
      end

      def consume_command headers, command
        consume_message headers, command, :command, Euston::CommandHeaders, :send_command_to_method
      end

      def consume_event_subscription headers, event
        consume_message headers, event, :event_subscription, Euston::EventHeaders, :send_event_subscription_to_method
      end

      def take_snapshot
        methods = self.class.instance_methods
        regex = self.class.take_snapshot_regexp
        methods = methods.map { |m| regex.match m }.compact

        raise "You tried to take a snapshot of #{self.class.name} but no snapshot method was found." if methods.empty?

        version = methods.map { |m| m[1].to_i }.sort.last
        name = self.class.take_snapshot_method_name version

        { :version => version, :payload => send(name) }
      end

      def version
        initial_version + uncommitted_events.length
      end

      protected

      def apply_event(type, version, body = {})
        event = Euston::Event.new(body.is_a?(OpenStruct) ? body.marshal_dump : body)
        event.headers.merge! :id => Euston.uuid.generate,
                             :type => type,
                             :version => version,
                             :timestamp => Time.now.to_f

        send_event_to_method Euston::EventHeaders.from_hash(event.headers), event.body
        uncommitted_events << event
      end

      def apply_snapshot snapshot
        if !snapshot.nil?
          version = snapshot.headers[:version]
          raise "Trying to load a snapshot of aggregate #{self.class.name} but it does not have a load_snapshot method for version #{version}!" unless respond_to? self.class.load_snapshot_method_name(version)

          name = self.class.load_snapshot_method_name version

          @log.debug "Applying snapshot: #{snapshot.inspect}"
          self.send name, snapshot.payload
        end
      end

      def apply_stream stream
        @aggregate_id = stream.stream_id
        @stream = stream

        events = stream.committed_events
        return if events.empty?

        raise "This aggregate cannot apply a historical event stream because it is not empty." unless uncommitted_events.empty? && initial_version == 0

        unless stream.committed_headers[:source_message].nil?
          committed_messages << stream.committed_headers[:source_message][:headers][:id]
        end

        events.each_with_index do |event, i|
          replay_event event.headers, event.body
        end
      end

      def publish_command command
        raise ArgumentError, 'Commands must subclass Euston::Command' unless command.is_a? Euston::Command
        raise Euston::Errors::InvalidCommandError, "An attempt was made to publish an invalid command from an aggregate root.\n\nAggregate id: #{@aggregate_id}\nAggregate type: #{self.class.name}\nCommand: #{command.to_hash}\nErrors: #{command.errors}" unless command.valid?

        uncommitted_commands << command
      end

      def replay_event headers, event
        headers = Euston::EventHeaders.from_hash(headers) if headers.is_a?(Hash)
        send_event_to_method headers, event
        @initial_version = initial_version + 1
      end

      def send_command_to_method headers, command
        deliver_message headers, command, :consumes_method_name, 'a command', "a 'consumes' block"
      end

      def send_event_to_method headers, event
        deliver_message headers, event, :applies_method_name, 'an event', "an 'applies' block"
      end

      def send_event_subscription_to_method headers, event
        deliver_message headers, event, :event_handler_method_name, 'an event', "a 'subscribes' block"
      end

      private

      def consume_message headers, body, message_type, headers_type, send_method
        headers = headers_type.from_hash(headers) if headers.is_a?(Hash)

        unless committed_messages.include? headers.id
          uncommitted_headers[:source_message_type] = message_type
          uncommitted_headers[:source_message]      = { headers: headers.to_hash, body: body } 
          
          self.send send_method, headers, body
        end

        self
      end

      def deliver_message headers, message, name_method, message_kind, expected_block_kind
        name = self.class.send(name_method, headers.type, headers.version).to_sym
        if respond_to? name
          @log.debug "Calling #{name} with: #{message.inspect}"
          m = method(name)
          case m.arity
          when 2, -1, -2
            m.call OpenStruct.new(headers.to_hash).freeze, OpenStruct.new(message).freeze
          when 1
            m.call OpenStruct.new(message).freeze
          else
            m.call
          end
        else
          raise "Couldn't deliver #{message_kind} (#{headers.type} v#{headers.version}) to #{self.class}. Did you forget #{expected_block_kind}?"
        end
      end
    end
  end
end
