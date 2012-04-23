require 'ap'
require 'require_all'
require 'euston'

require_rel 'scenarios'

module GolfScenario
  extend ActiveSupport::Concern

  included do
    let(:course_id) { Uuid.generate }

    let(:message_class_finder) do
      namespaces = Euston::Namespaces.new namespace, namespace, namespace
      Euston::MessageClassFinder.new namespaces
    end

    let(:namespace) { Scenarios::GolfCourse }

    let(:player_id) { Uuid.generate }

    let(:time)      { Time.now.utc + 1000 + rand(1000) }

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

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.include GolfScenario, :golf
end

