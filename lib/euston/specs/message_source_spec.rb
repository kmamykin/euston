module Euston
  module MessageSourceSpec
    extend ::ActiveSupport::Concern
    extend ::RSpec::Matchers::DSL if Object.const_defined? 'RSpec'

    included do
      before do
        @euston_largest_referenced_message_positions = { command: 0, event: 0 }
      end

      let(:message_source) do
        sequence = 1
        commits = []

        events = [@euston_message_source_history].flatten.compact.map do |event|
          event.to_hash.tap do |hash|
            hash[:headers][:sequence] = sequence
            sequence = sequence + 1
          end
        end

        unless events.empty?
          commits << Euston::Commit.new(message_source_id: full_message_source_id,
                                        events: events,
                                        id: Uuid.generate,
                                        sequence: 1)
        end

        history = Euston::MessageSourceHistory.new id: message_source_id, commits: commits, snapshot: snapshot, type: message_source_type
        message_source_type.new message_class_finder, history
      end

      let(:command_namespaces)          { [] }
      let(:euston_namespaces)           { Euston::Namespaces.new commands: command_namespaces, events: event_namespaces, message_handlers: message_handler_namespaces }
      let(:event_namespaces)            { [] }
      let(:message_source_id)           { Uuid.generate }
      let(:full_message_source_id)      { Euston::MessageSourceId.new message_source_id, message_source_type }
      let(:message_class_finder)        { Euston::MessageClassFinder.new euston_namespaces }
      let(:message_handler_namespaces)  { [] }
      let(:snapshot)                    { nil }

      subject do
        run_scenario
        @euston_commit_created
      end

      private

      def run_scenario
        begin
          message_source.when(commit_created: ->(commit)    { @euston_commit_created = commit },
                              snapshot_taken: ->(snapshot)  { @euston_snapshot_taken = snapshot })

          [@euston_incoming_messages].flatten.compact.each do |message|
            if message.is_a? Hash
              message_class = Factory.build("#{message[:headers][:type]}_v#{message[:headers][:version]}".to_sym).class
              message = message_class.headers(message[:headers]).body(message[:body])
            end

            if message.valid?
              message_source.consume message.to_hash
            else
              raise <<-EOS
An attempt was made to consume an invalid message. Check the messages you are providing to this spec.

Message:

#{message.to_hash}

Errors:

#{message.errors.full_messages}
              EOS
            end
          end

          message_source.take_snapshot if message_source.supports_snapshots?
        rescue => e
          if @expect_error
            @exception_caught = e
          else
            raise e
          end
        end
      end
    end

    module ClassMethods
      def error_raised &block
        describe 'the error raised' do
          before  { @expect_error = true }

          subject do
            run_scenario
            @exception_caught
          end

          it { should_not be_nil }

          instance_eval(&block) if block_given?
        end
      end

      def history &block
        append_messages_to_array :@euston_message_source_history, &block
      end

      def incoming_messages &block
        append_messages_to_array :@euston_incoming_messages, &block
      end

      def outgoing_command position, &block
        outgoing_message :command, position, block
      end

      def outgoing_event position, &block
        outgoing_message :event, position, block
      end

      def snapshot &block
        prepare_snapshot &block
      end

      def snapshot_body &block
        prepare_snapshot do
          { body: instance_eval(&block) }
        end
      end

      def snapshot_taken &block
        describe "a snapshot is taken" do
          subject do
            run_scenario
            OpenCascade.new @euston_snapshot_taken.body
          end

          instance_eval &block
        end
      end

      private

      def append_messages_to_array array_name, &block
        before do
          new_messages = instance_eval &block
          array = instance_variable_get(array_name) || []
          array.push *([new_messages].flatten.compact)
          instance_variable_set array_name, array
        end
      end

      def prepare_snapshot &block
        let(:snapshot) do
          defaults = { message_source_id: full_message_source_id,
                       sequence:          1 }

          Euston::Snapshot.new defaults.merge instance_eval(&block)
        end
      end

      def outgoing_message message_type, position, block
        before do
          if @euston_largest_referenced_message_positions[message_type] < position
            @euston_largest_referenced_message_positions[message_type] = position
          end
        end

        describe "the #{message_type} at position #{position}" do
          subject do
            run_scenario
            messages = @euston_commit_created.send "#{message_type}s".to_sym
            raise "Insufficient outgoing #{message_type}s to satisfy request for #{message_type} at position #{position}." unless messages.length >= position
            OpenCascade.new messages[position - 1].to_hash
          end

          instance_eval &block
        end

        describe "the number of uncommitted #{message_type}s" do
          it { should have_produced(@euston_largest_referenced_message_positions[message_type]).send "#{message_type}s" }
        end
      end
    end
  end
end
