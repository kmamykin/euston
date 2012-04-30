module Euston
  module EventSource
    extend ActiveSupport::Concern
    include Hollywood
    include CommandHandler
    include EventHandler

    included do
      def initialize message_class_finder, history = nil
        @event_source_history = history || EventSourceHistory.empty
        @message_class_finder = message_class_finder
        initialization if self.class.message_map.has_initializer?
        restore_state_from_history
        @idempotence_monitor = IdempotenceMonitor.new @event_source_history
      end

      def consume message
        @commit = Commit.new event_source_id: @event_source_history.id,
                             sequence: @event_source_history.next_sequence,
                             origin: message,
                             type: self.class

        unless @idempotence_monitor.already_encountered? message
          call_state_change_function message[:headers][:type],
                                     message[:headers][:version],
                                     message[:headers],
                                     message[:body]

          @idempotence_monitor.memorize message[:headers][:id]
        end

        commit = @commit
        @commit = nil

        callback :commit_created, commit
      end

      def take_snapshot
        snapshot_metadata = self.class.message_map.get_newest_snapshot_metadata
        body = send snapshot_metadata[:method_name]
        snapshot = Snapshot.new event_source_id: @event_source_history.id,
                                sequence: @event_source_history.sequence,
                                type: self.class.to_s,
                                version: snapshot_metadata[:version],
                                idempotence_message_ids: @idempotence_monitor.message_ids,
                                body: body

        callback :snapshot_taken, snapshot
      end

      private

      def publish_command command
        unless command.valid?
          raise InvalidCommandError, "An attempt was made to publish an invalid command from event source #{self.class}. Errors detected:\n\n#{command.errors.full_messages}"
        end

        @commit.store_command command

        self
      end

      def restore_state_from_history
        unless @event_source_history.snapshot.nil?
          method_name = self.class.message_map.get_method_name_to_load_snapshot @event_source_history.snapshot

          if respond_to? method_name
            send method_name, @event_source_history.snapshot.body
          else
            raise UnknownSnapshotError, "An attempt was made to load from an unsupported snapshot version #{@event_source_history.snapshot.version} in event source #{self.class}."
          end
        end

        @event_source_history.commits.each do |commit|
          commit.events.each do |event|
            call_state_change_function event[:headers][:type], event[:headers][:version], event[:headers], event[:body]
          end
        end
      end

      def transition_to transition, version, body
        event_class = @message_class_finder.find_event transition, version
        event = event_class.new body

        unless event.valid?
          raise InvalidTransitionStateError, "Invalid attempt to transition to state #{transition} version #{version} in event source #{self.class}. Errors detected:\n\n#{event.errors.full_messages}"
        end

        @commit.store_event event
        call_state_change_function transition, version, nil, body

        self
      end
    end

    module ClassMethods
      def snapshots
        @message_map_section = :snapshots
      end

      def transitions
        @message_map_section = :transitions
      end

      def initialization &block
        message_map.define_initializer &block
      end
    end
  end
end
