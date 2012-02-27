describe 'event source command publishing' do  
  module ESCP1
    class OrderDogfood < Euston::Command
      version 1 do
        validates :dog_id,    presence: true
        validates :quantity,  presence: true
      end
    end

    class DogWalked < Euston::Event
      version 1 do
        validates :dog_id,    presence: true
        validates :distance,  presence: true
      end
    end
  end

  let(:dog_id)                { Uuid.generate }
  let(:event)                 { ESCP1::DogWalked.v(1).new(dog_id: dog_id, distance: (1..10).to_a.sample).to_hash }
  let(:event_stream)          { instance.consume event }
  let(:message_class_finder)  { Euston::MessageClassFinder.new ESCP1 }
  
  context 'when the command being published is valid' do
    module ESCP1
      class ValidEventSourceExample
        include Euston::EventSource

        events

        dog_walked :dog_id do |headers, body|
          publish_command OrderDogfood.v(1).new dog_id: body[:dog_id], quantity: 1
        end
      end
    end

    let(:instance)  { ESCP1::ValidEventSourceExample.new message_class_finder }
    subject         { event_stream }

    its(:commands) { should have(1).item }

    describe "the first published command's headers" do
      subject { event_stream.commands[0][:headers] }

      its([:type])    { should == :order_dogfood }
      its([:version]) { should == 1 }
    end

    describe "the first published command's body" do
      subject { event_stream.commands[0][:body] }

      its([:dog_id])   { should == dog_id }
      its([:quantity]) { should == 1 }
    end
  end

  context 'when the command being published is invalid' do
    module ESCP1
      class InvalidEventSourceExample
        include Euston::EventSource

        events

        dog_walked :dog_id do |headers, body|
          publish_command OrderDogfood.v(1).new xyz: :abc
        end
      end
    end

    let(:exceptions)  { [] }
    let(:instance)    { ESCP1::InvalidEventSourceExample.new message_class_finder }
    
    before do
      begin
        event_stream
      rescue Euston::InvalidCommandError => e
        exceptions << e
      end
    end

    subject { exceptions }

    it { should have(1).item }
  end
end
