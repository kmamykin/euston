describe 'event source hydration' do
  module ESH1
    class DogWalked < Euston::Event
      version 1 do
        validates :dog_id,    presence: true
        validates :distance,  presence: true
      end
    end

    class DistanceIncreased < Euston::Event
      version 1 do
        validates :dog_id,          presence: true
        validates :total_distance,  presence: true
      end
    end
  end

  let(:event)                 { ESH1::DogWalked.v(1).new(dog_id: dog_id, distance: distance).to_hash }
  let(:message_class_finder)  { Euston::MessageClassFinder.new Euston::Namespaces.new(ESH1, ESH1, ESH1) }
  let(:distance)              { (1..10).to_a.sample }
  let(:dog_id)                { Uuid.generate }

  context 'with a event source with no snapshot capability' do
    module ESH1
      class SimpleEventSource
        include Euston::EventSource

        initialization do
          @total_distance = 0
        end

        events

        dog_walked do |headers, body|
          transition_to :distance_increased, 1, dog_id: body[:dog_id], total_distance: @total_distance + body[:distance]
        end

        transitions

        distance_increased do |body|
          @total_distance = body[:total_distance]
        end
      end
    end

    let(:historical_distance) { (1..10).to_a.sample }
    let(:historical_event)    { ESH1::DistanceIncreased.v(1).new(dog_id: dog_id, total_distance: historical_distance).to_hash }

    let(:instance) do
      ESH1::SimpleEventSource.new(message_class_finder, history).when(:commit_created) do |commit|
        @commit = commit
      end
    end

    context 'when the event source is loaded with history containing commits only' do
      let(:history) { Euston::EventSourceHistory.new commits: [ Euston::Commit.new(nil, [ historical_event ]) ] }

      before  { instance.consume event }
      subject { @commit.events }

      it { should have(1).item }

      describe 'the first event' do
        subject { @commit.events[0][:body] }

        its([:total_distance]) { should == distance + historical_distance }
      end
    end

    context 'when the event source is loaded with history containing snapshots' do
      let(:exceptions)  { [] }
      let(:history)     { Euston::EventSourceHistory.new commits: [ Euston::Commit.new(nil, [ historical_event ]) ], snapshot: snapshot }
      let(:snapshot)    { Euston::Snapshot.new ESH1::SimpleEventSource, 1, [], {} }

      before do
        begin
          instance.consume event
        rescue Euston::UnknownSnapshotError => e
          exceptions << e
        end
      end

      subject { exceptions }

      it { should have(1).item }
    end
  end

  context 'with a snapshot' do
    module ESH1
      class SnapshottingEventSource
        include Euston::EventSource

        attr_reader :total_distance, :name

        events

        dog_walked do |headers, body|
          transition_to :distance_increased, 1, dog_id: body[:dog_id], total_distance: @total_distance + body[:distance]
        end

        transitions

        distance_increased do |body|
          @total_distance = body[:total_distance]
        end

        snapshots

        load_from 1 do |payload|
          @name           = payload[:name]
          @total_distance = payload[:total_distance]
        end

        save_to 1 do
          { name: @name, total_distance: @total_distance }
        end
      end
    end

    let(:name)            { Uuid.generate }
    let(:snapshot)        { Euston::Snapshot.new ESH1::SnapshottingEventSource, 1, [], name: name, total_distance: total_distance }
    let(:total_distance)  { (1..100).to_a.sample }

    let(:instance) do
      ESH1::SnapshottingEventSource.new(message_class_finder, history)
        .when(commit_created:   ->(commit)    { @commit = commit },
              snapshot_created: ->(snapshot)  { @snapshot = snapshot })
    end

    describe 'when the event source is loaded from a snapshot and no commits' do
      let(:history) { Euston::EventSourceHistory.new snapshot: snapshot }

      subject { instance }

      its(:name)            { should == name }
      its(:total_distance)  { should == total_distance }
    end

    describe 'when the event source is loaded from a snapshot and an commit' do
      let(:historical_distance) { total_distance + 1 + (1..10).to_a.sample }
      let(:historical_event)    { ESH1::DistanceIncreased.v(1).new(dog_id: dog_id, total_distance: historical_distance).to_hash }
      let(:history)             { Euston::EventSourceHistory.new commits: [ Euston::Commit.new(nil, [ historical_event ]) ], snapshot: snapshot }

      subject { instance }

      its(:name)            { should == name }
      its(:total_distance)  { should == historical_distance }
    end

    describe 'when a snapshot is taken' do
      let(:historical_distance) { (1..10).to_a.sample }
      let(:historical_event)    { ESH1::DistanceIncreased.v(1).new(dog_id: dog_id, total_distance: historical_distance).to_hash }
      let(:history)             { Euston::EventSourceHistory.new commits: [ Euston::Commit.new(nil, [ historical_event ]) ], snapshot: snapshot }

      before  { instance.take_snapshot }
      subject { @snapshot.payload }

      its([:name])            { should == name }
      its([:total_distance])  { should == historical_distance }
    end
  end
end
