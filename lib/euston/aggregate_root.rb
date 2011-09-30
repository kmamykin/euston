module Euston
  module AggregateRoot
    extend ActiveSupport::Concern

    module ClassMethods
      include AggregateRootPrivateMethodNames
      include AggregateRootDslMethods

      def hydrate stream, snapshot = nil
        instance = self.new
        instance.send :apply_snapshot, snapshot unless snapshot.nil?
        instance.send :apply_stream, stream
        instance
      end
    end

    module InstanceMethods
      def initialize aggregate_id = nil
        @aggregate_id = aggregate_id
      end

      attr_reader :aggregate_id

      def initial_version
        @initial_version ||= 0
      end

      def has_uncommitted_changes?
        !uncommitted_events.empty?
      end

      def committed_commands
        @committed_commands ||= []
      end

      def uncommitted_events
        @uncommitted_events ||= []
      end

      def consume_command(headers, command)
        headers = Euston::CommandHeaders.from_hash(headers) if headers.is_a?(Hash)
        return if committed_commands.include? headers.id

        @current_headers = headers
        @current_command = command

        handle_command headers, command
        self
      end

      def take_snapshot
        methods = self.class.instance_methods
        regex = /__take_snapshot__v(\d+)__/
        methods = methods.map { |m| regex.match m }.compact

        raise "You tried to take a snapshot of #{self.class.name} but no snapshot method was found." if methods.empty?

        version = methods.map { |m| m[1].to_i }.sort.last
        name = self.class.take_snapshot_method_name version

        { :version => version, :payload => send(name) }
      end

      def replay_event(headers, event)
        headers = Euston::EventHeaders.from_hash(headers) if headers.is_a?(Hash)
        command = headers.command
        committed_commands << command[:id] unless command.nil? || committed_commands.include?(command[:id])

        handle_event headers, event
        @initial_version = initial_version + 1
      end

      def version
        initial_version + uncommitted_events.length
      end

      protected

      def apply_event(type, version, body = {})
        event = Euston::EventStore::EventMessage.new(body.is_a?(Hash) ? body : body.marshal_dump)
        event.headers.merge! :id => Euston.uuid.generate,
                             :type => type,
                             :version => version,
                             :timestamp => Time.now.to_f

        unless @current_headers.nil?
          event.headers.merge! :command => @current_headers.to_hash.merge(:body => @current_command)
        end

        handle_event Euston::EventHeaders.from_hash(event.headers), event.body
        uncommitted_events << event
      end

      def apply_snapshot snapshot
        if !snapshot.nil?
          version = snapshot.headers[:version]
          raise "Trying to load a snapshot of aggregate #{self.class.name} but it does not have a load_snapshot method for version #{version}!" unless respond_to? self.class.load_snapshot_method_name(version)

          name = self.class.load_snapshot_method_name version
          self.send name, snapshot.payload
        end
      end

      def apply_stream stream
        @aggregate_id = stream.stream_id

        events = stream.committed_events
        return if events.empty?

        raise "This aggregate cannot apply a historical event stream because it is not empty." unless uncommitted_events.empty? && initial_version == 0

        events.each_with_index do |event, i|
          replay_event Euston::EventHeaders.from_hash(event.headers), event.body
        end
      end

      def handle_command headers, command
        deliver_message headers, command, :consumes_method_name, 'a command', "a 'consumes' block"
      end

      def handle_event headers, event
        deliver_message headers, event, :applies_method_name, 'an event', "an 'applies' block"
      end

      private

      def deliver_message headers, message, name_method, message_kind, expected_block_kind
        name = self.class.send name_method, headers.type, headers.version

        if respond_to? name.to_sym
          method(name).call OpenStruct.new(message).freeze
        else
          raise "Couldn't deliver #{message_kind} (#{headers.type} v#{headers.version}) to #{self.class}. Did you forget #{expected_block_kind}?"
        end
      end
    end
  end
end
