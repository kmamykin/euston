module Euston
  module EventSource
    extend ActiveSupport::Concern

    included do
      def initialize message_class_finder, history = EventSourceHistory.empty
        @message_class_finder = message_class_finder

        unless history.snapshot.nil?
          method_name = self.class.message_map.get_method_name_to_load_snapshot history.snapshot
          
          if respond_to? method_name
            send method_name, history.snapshot.payload
          else
            raise UnknownSnapshotError, "An attempt was made to load from an unsupported snapshot version #{history.snapshot.version} in event source #{self.class}."
          end
        end

        history.event_streams.each do |event_stream|
          event_stream.events.each do |event|
            call_state_change_function event[:headers][:type], event[:headers][:version], event[:body]
          end
        end
      end

      def consume message
        @event_stream = EventStream.new message
        
        method_name = self.class.message_map.get_method_name_for_message message
        send method_name, message[:headers], message[:body]

        @event_stream
      end

      def take_snapshot
        snapshot_metadata = self.class.message_map.get_newest_snapshot_metadata
        payload = send snapshot_metadata[:method_name]
        Euston::Snapshot.new self.class, snapshot_metadata[:version], payload
      end

      private

      def call_state_change_function transition, version, body
        method_name = self.class.message_map.get_method_name_for_message(transition, version).to_sym

        send method_name, marshal_dup(body)
      end

      def publish_command command
        unless command.valid?
          raise InvalidCommandError, "An attempt was made to publish an invalid command from event source #{self.class}. Errors detected:\n\n#{command.errors.full_messages}"
        end

        @event_stream.commands << command.to_hash
      end

      def transition_to transition, version, body
        event_class = @message_class_finder.find_event transition, version
        event = event_class.new body

        unless event.valid?
          raise InvalidTransitionStateError, "Invalid attempt to transition to state #{transition} version #{version} in event source #{self.class}. Errors detected:\n\n#{event.errors.full_messages}"
        end

        @event_stream.store_event transition, version, body
        call_state_change_function transition, version, body
      end
    end

    module ClassMethods
      def commands
        @message_map_section = :commands
      end

      def events
        @message_map_section = :events
      end

      def snapshots
        @message_map_section = :snapshots
      end

      def transitions
        @message_map_section = :transitions
      end

      def message_map
        @message_map ||= begin
          map = EventSourceMessageMap.new self
          map.message_defined  { |name, block| define_method name, &block }
          map.snapshot_defined { |name, block| define_method name, &block }
          map
        end
      end

      def method_missing method, *args, &block
        if @message_map_section.nil?
          super.method_missing method, *args, &block
        elsif @message_map_section == :snapshots
          if message_map.snapshot_method? method
            message_map.define_snapshot method, args, &block
          else
            super.method_missing method, *args, &block
          end
        else
          message_map.define @message_map_section, method, args, &block
        end
      end
    end
  end
end
