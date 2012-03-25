describe 'event source command invocation' do
  context 'a command is consumed which causes a transition to a new state' do
    module ESCS1
      class EventSourceExample
        include Euston::EventSource

        commands

        walk_dog :dog_id do |headers, body|
          transition_to :dog_walked, 1, body
        end

        transitions

        dog_walked do |body|
          @distance = body[:distance]
        end
      end

      class WalkDog < Euston::Command
        version 1 do
          validates :dog_id,    presence: true
          validates :distance,  presence: true
        end
      end

      class DogWalked < Euston::Event
        version 1 do
          validates :dog_id,    presence: true
          validates :distance,  presence: true
        end
      end
    end

    let(:command)               { ESCS1::WalkDog.v(1).new(dog_id: dog_id, distance: distance).to_hash }
    let(:dog_id)                { Uuid.generate }
    let(:distance)              { (1..100).to_a.sample }
    let(:exceptions)            { [] }
    let(:message_class_finder)  { Euston::MessageClassFinder.new Euston::Namespaces.new(ESCS1, ESCS1, ESCS1) }

    let(:instance) do
      ESCS1::EventSourceExample.new(message_class_finder).when(:commit_created) do |commit|
        @commit = commit
      end
    end

    before { instance.consume command }

    subject { @commit }

    its(:origin)  { should == command }
    its(:events)  { should have(1).item }

    describe 'the first event in the event stream' do
      subject { @commit.events[0] }

      it              { should be_a Hash }
      its([:headers]) { should be_a Hash }
      its([:body])    { should be_a Hash }

      describe 'headers' do
        subject { @commit.events[0][:headers] }

        its([:type])    { should == :dog_walked }
        its([:version]) { should == 1 }
      end

      describe 'body' do
        subject { @commit.events[0][:body] }

        its([:dog_id])    { should == dog_id }
        its([:distance])  { should == distance }
      end
    end
  end
end
