module Euston
  module MessageSource
    extend ActiveSupport::Concern
    include Hollywood
    include CommandHandler
    include EventHandler

    included do
      def initialize message_class_finder, history = nil
        @message_source_history = history || MessageSourceHistory.empty(self.class)
        @message_class_finder = message_class_finder
        initialization if self.class.message_map.has_initializer?
        restore_state_from_history
      end

      def consume message
        @commit = Commit.new message_source_id: @message_source_history.message_source_id,
                             sequence: @message_source_history.next_sequence,
                             origin: message

        call_state_change_function message[:headers][:type],
                                   message[:headers][:version],
                                   message[:headers],
                                   message[:body]

        commit = @commit
        @commit = nil

        callback :commit_created, commit
      end

      def take_snapshot
        snapshot_metadata = self.class.message_map.get_newest_snapshot_metadata
        body = send snapshot_metadata[:method_name]

        snapshot = Snapshot.new message_source_id: @message_source_history.message_source_id,
                                sequence: @message_source_history.sequence,
                                version: snapshot_metadata[:version],
                                body: body

        callback :snapshot_taken, snapshot
      end

      def supports_snapshots?
        self.class.message_map.has_snapshot_metadata?
      end

      private

      def message_source_id
        @message_source_history.message_source_id.id
      end

      def publish_command command, opts = {}
        unless command.valid?
          raise InvalidCommandError, "An attempt was made to publish an invalid command from message source #{self.class}. Errors detected:\n\n#{command.errors.full_messages}"
        end

        @commit.store_command command, opts

        self
      end

      def restore_state_from_history
        unless @message_source_history.snapshot.nil?
          method_name = self.class.message_map.get_method_name_to_load_snapshot @message_source_history.snapshot

          if respond_to? method_name
            send method_name, @message_source_history.snapshot.body
          else
            raise UnknownSnapshotError, "An attempt was made to load from an unsupported snapshot version #{@message_source_history.snapshot.version} in message source #{self.class}."
          end
        end

        @message_source_history.commits.each do |commit|
          commit.events.each do |event|
            call_state_change_function event[:headers][:type],
                                       event[:headers][:version],
                                       event[:headers],
                                       event[:body]
          end
        end
      end

      def transition_to transition, version, headers, body = nil
        event_class = @message_class_finder.find_event transition, version
        headers, body = {}, headers if !headers.nil? && body.nil?

        opts = {}
        opts[:correlated] = headers.delete :correlated if headers.has_key? :correlated

        event = event_class.new headers, body

        unless event.valid?
          raise InvalidTransitionStateError, "Invalid attempt to transition to state #{transition} version #{version} in message source #{self.class}. Errors detected:\n\n#{event.errors.full_messages}"
        end

        @commit.store_event event, opts
        event = event.to_hash
        call_state_change_function transition, version, event[:headers], event[:body]

        self
      end
    end

    module ClassMethods
      def id value
        message_map.define_identifier value
      end

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
