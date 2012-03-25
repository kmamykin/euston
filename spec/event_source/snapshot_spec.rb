describe 'event source snapshots' do
  module ESSN1
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

  let(:event)                 { ESSN1::DogWalked.v(1).new(dog_id: dog_id, distance: distance).to_hash }
  let(:message_class_finder)  { Euston::MessageClassFinder.new Euston::Namespaces.new(ESSN1, ESSN1, ESSN1) }
  let(:distance)              { (1..10).to_a.sample }
  let(:dog_id)                { Uuid.generate }

  context 'with a event source that has no snapshot capability' do
    module ESSN1
      class UnsnapshottableEventSource
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

    let(:instance) do
      ESSN1::UnsnapshottableEventSource.new message_class_finder
    end

    context 'when a snapshot is requested' do
      before do
        instance.consume event

        begin
          instance.take_snapshot
        rescue Euston::UnknownSnapshotError => e
          @exception = e
        end
      end

      subject { @exception }

      it { should be_a Euston::UnknownSnapshotError }
    end
  end

  context 'with a event source that has a snapshot capability' do
    module ESSN1
      class SnapshottingEventSource
        include Euston::EventSource

        initialization do
          @total_distance = 0
        end

        events

        dog_walked do |body|
          transition_to :distance_increased, 1, dog_id: body[:dog_id], total_distance: @total_distance + body[:distance]
        end

        transitions

        distance_increased do |body|
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

    let(:instance) do
      ESSN1::SnapshottingEventSource.new(message_class_finder).when(:snapshot_created) do |snapshot|
        @snapshot = snapshot
      end
    end

    context 'when a snapshot is requested' do
      before do
        instance.consume event
        instance.take_snapshot
      end

      subject { @snapshot }

      its(:type)        { should == ESSN1::SnapshottingEventSource }
      its(:version)     { should == 1}
      its(:message_ids) { should include event[:headers][:id] }

      describe 'it contains the correct snapshot payload' do
        subject { @snapshot.payload }

        its([:total_distance])  { should == distance }
      end
    end
  end
end
