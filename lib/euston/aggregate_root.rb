module Euston
  module AggregateRoot
    extend ActiveSupport::Concern

    module ClassMethods
      def applies event, version, &consumer
        define_method "__consume__#{event}__v#{version}" do |*args| instance_exec *args, &consumer end
      end

      def consumes *arguments, &consumer #*args is an array of symbols plus an optional options hash at the end
        commands, options = [], {}
        while (arg = arguments.shift) do
          commands << arg if arg.is_a?(Symbol)
            options = arg if arg.is_a?(Hash)
        end
        commands.each do |command|
          define_method "__consume__#{command}" do |*args| instance_exec *args, &consumer end

          map_command :map_command_as_aggregate_method, self, command, options
        end
      end

      def created_by command, options = {}, &consumer
        define_method "__consume__#{command}" do |*args| instance_exec *args, &consumer end

        map_command :map_command_as_aggregate_constructor, self, command, options
      end

      def hydrate(stream)
        instance = self.new
        instance.send :reconstitute_from_history, stream
        instance
      end

      private

      def map_command(entry_point, type, command, opts)
        id = opts.has_key?(:id) ? opts[:id] : :id
        to_i = opts.key?(:to_i) ? opts[:to_i] : []

        Euston::AggregateCommandMap.send entry_point, type, command, id, to_i
      end
    end

    module InstanceMethods
      def initialize aggregate_id = nil
        @aggregate_id = aggregate_id unless aggregate_id.nil?
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

      def handle_command(headers, command)
        name = "__consume__#{headers.type}"
        method(name).call OpenStruct.new(command).freeze
      end

      def handle_event(headers, event)
        name = "__consume__#{headers.type}__v#{headers.version}"
        if respond_to? name.to_sym
          method(name).call OpenStruct.new(event).freeze
        else
          raise "Couldn't find an event handler for #{headers.type} (v#{headers.version}) on #{self.class}. Did you forget an 'applies' block?"
        end
      end

      def reconstitute_from_history(stream)
        events = stream.committed_events
        return if events.empty?

        raise "This aggregate cannot apply a historical event stream because it is not empty." unless uncommitted_events.empty? && initial_version == 0

        @aggregate_id = stream.stream_id

        events.each_with_index do |event, i|
          replay_event Euston::EventHeaders.from_hash(event.headers), event.body
        end
      end
    end
  end
end