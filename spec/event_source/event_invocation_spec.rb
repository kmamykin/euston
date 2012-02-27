describe 'event source event invocation' do
  context 'a command is consumed which causes a transition to a new state' do
    module ESES1
      class EventSourceExample
        include Euston::EventSource

        events

        dog_walked :dog_id do |headers, body|
          transition_to :dog_sleeping, 1, dog_id: body[:dog_id], drooling: true
        end

        transitions

        dog_sleeping do |body|
          @drooling = body[:drooling]
        end
      end

      class DogWalked < Euston::Event
        version 1 do
          validates :dog_id, presence: true
          validates :distance, presence: true
        end
      end

      class DogSleeping < Euston::Event
        version 1 do
          validates :dog_id, presence: true
          validates :drooling, presence: true
        end
      end
    end

    let(:event)                 { ESES1::DogWalked.v(1).new(dog_id: dog_id, distance: distance).to_hash }
    let(:dog_id)                { Uuid.generate }
    let(:distance)              { (1..100).to_a.sample }
    let(:event_stream)          { instance.consume event }
    let(:instance)              { ESES1::EventSourceExample.new message_class_finder }
    let(:message_class_finder)  { Euston::MessageClassFinder.new Euston::Namespaces.new(ESES1, ESES1, ESES1) }
    
    subject { event_stream }

    its(:source_message)  { should == event }
    its(:events)          { should have(1).item }

    describe 'the first event in the event stream' do
      subject { event_stream.events[0] }

      it              { should be_a Hash }
      its([:headers]) { should be_a Hash }
      its([:body])    { should be_a Hash }

      describe 'headers' do
        subject { event_stream.events[0][:headers] }

        its([:type])    { should == :dog_sleeping }
        its([:version]) { should == 1 }
      end

      describe 'body' do
        subject { event_stream.events[0][:body] }

        its([:dog_id])    { should == dog_id }
        its([:drooling])  { should be_true }
      end
    end
  end
end
