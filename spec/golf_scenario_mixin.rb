module GolfScenarioMixin
  extend ActiveSupport::Concern

  included do
    let(:course_id)                 { Uuid.generate }
    let(:event_source_id)           { course_id }
    let(:message_class_finder)      { Euston::MessageClassFinder.new namespaces }
    let(:namespace)                 { Scenarios::GolfCourse }
    let(:namespaces)                { Euston::Namespaces.new message_handlers: namespace, commands: namespace, events: namespace }
    let(:new_event_source_history)  { Euston::EventSourceHistory.new id: course_id }
    let(:player_id)                 { Uuid.generate }
    let(:time)                      { Time.now.utc + 1000 + rand(1000) }

    def scorer history = nil
      @scorer ||= namespace::Scorer.new(message_class_finder, history).when(
        commit_created: ->(commit)    { @commit = commit },
        snapshot_taken: ->(snapshot)  { @snapshot = snapshot })
    end

    def secretary history = nil
      @secretary ||= namespace::Secretary.new(message_class_finder, history).when(
        commit_created: ->(commit)    { @commit = commit },
        snapshot_taken: ->(snapshot)  { @snapshot = snapshot })
    end

    def starter history = nil
      @starter ||= namespace::Starter.new(message_class_finder, history).when(
        commit_created: ->(commit)    { @commit = commit },
        snapshot_taken: ->(snapshot)  { @snapshot = snapshot })
    end
  end
end
