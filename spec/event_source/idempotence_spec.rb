describe 'event source idempotence' do
  module ESI1
    class WalkDog < Euston::Command
      version 1 do
        validates :dog_id,    presence: true
        validates :distance,  presence: true
      end
    end

    class DogWalked < Euston::Event
      version 1 do
        validates :dog_id,          presence: true
        validates :total_distance,  presence: true
      end
    end

    class StandardEventSource
      include Euston::EventSource

      attr_reader :total_distance, :name

      events

      walk_dog do |body|
        transition_to :dog_walked, 1, dog_id: body[:dog_id], total_distance: @total_distance + body[:distance]
      end

      transitions

      dog_walked do |body|
        @total_distance = body[:total_distance]
      end

      snapshots

      load_from 1 do |payload|
        @total_distance = payload[:total_distance]
      end

      save_to 1 do
        { total_distance: @total_distance }
      end
    end
  end

  let(:command)               { ESI1::WalkDog.v(1).new(dog_id: dog_id, distance: distance).to_hash }
  let(:message_class_finder)  { Euston::MessageClassFinder.new Euston::Namespaces.new(ESI1, ESI1, ESI1) }
  let(:distance)              { (1..10).to_a.sample }
  let(:dog_id)                { Uuid.generate }
  let(:historical_distance)   { (1..10).to_a.sample }

  let(:instance) do
    ESI1::StandardEventSource.new(message_class_finder, history).when(:commit_created) do |commit|
      @commit = commit
    end
  end

  before  { instance.consume command }
  subject { @commit }

  context "with an event source loaded solely from commits which already include the command's id" do
    let(:historical_event)  { ESI1::DogWalked.v(1).new(dog_id: dog_id, total_distance: historical_distance).to_hash }
    let(:history)           { Euston::EventSourceHistory.new commits: [ Euston::Commit.new(command, [ historical_event ]) ] }

    it { should be_empty }
  end

  context "with an event source loaded solely from snapshots which already include the command's id" do
    let(:snapshot)  { Euston::Snapshot.new ESI1::StandardEventSource, 1, [command[:headers][:id]], total_distance: historical_distance }
    let(:history)   { Euston::EventSourceHistory.new snapshot: snapshot }

    it { should be_empty }
  end
end
