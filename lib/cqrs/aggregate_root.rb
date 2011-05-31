module Cqrs
  module AggregateRoot
    extend ActiveSupport::Concern

    module ClassMethods
      def applies event, version, &consumer
        define_method "__consume__#{event}__v#{version}" do |*args| instance_exec *args, &consumer end
      end
      
      def consumes command, options = {}, &consumer
        define_method "__consume__#{command}" do |*args| instance_exec *args, &consumer end

        map_command :map_command_as_aggregate_method, self, command, options
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
        
        Cqrs::AggregateCommandMap.send entry_point, type, command, id, to_i
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
        return if committed_commands.include? headers.id

        @current_headers = headers
        @current_command = command

        handle_command headers, command
      end

      def replay_event(headers, event)
        command = headers.command
        committed_commands << command unless command.nil? || committed_commands.any? { |c| c[:id] == command[:id] }

        handle_event headers, event
        @initial_version = initial_version + 1
      end

      def version
        initial_version + uncommitted_events.length
      end

      protected

      def apply_event(type, version, body = {})
        event = EventStore::EventMessage.new(body.is_a?(Hash) ? body : body.marshal_dump)
        event.headers.merge! :id => Cqrs.uuid.generate,
                             :type => type,
                             :version => version,
                             :timestamp => Time.now.to_f

        unless @current_headers.nil?
          event.headers.merge! :command => @current_headers.to_hash.merge(:body => @current_command)
        end

        @aggregate_id = event.body[:id] if initial_version == 0 && uncommitted_events.empty?

        handle_event Cqrs::EventHeaders.from_hash(event.headers), event.body
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
          replay_event Cqrs::EventHeaders.from_hash(event.headers), event.body
        end
      end
    end
  end
end