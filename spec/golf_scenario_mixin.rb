module GolfScenarioMixin
  extend ActiveSupport::Concern

  included do
    let(:course_id)                 { Uuid.generate }
    let(:message_source_id)           { course_id }
    let(:message_class_finder)      { Euston::MessageClassFinder.new namespaces }
    let(:namespace)                 { Scenarios::GolfCourse }
    let(:namespaces)                { Euston::Namespaces.new message_handlers: namespace, commands: namespace, events: namespace }
    let(:player_id)                 { Uuid.generate }
    let(:time)                      { Time.now.utc + 1000 + rand(1000) }

    def new_event_source_history type
      Euston::MessageSourceHistory.new id: course_id, type: type
    end

    def new_message_source_id type
      Euston::MessageSourceId.new course_id, type
    end

    def new_scorer_event_source_history
      new_event_source_history namespace::Scorer
    end

    def new_scorer_message_source_id
      new_message_source_id namespace::Scorer
    end

    def new_secretary_event_source_history
      new_event_source_history namespace::Secretary
    end

    def new_secretary_message_source_id
      new_message_source_id namespace::Secretary
    end

    def new_starter_event_source_history
      new_event_source_history namespace::Starter
    end

    def new_starter_message_source_id
      new_message_source_id namespace::Starter
    end

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
