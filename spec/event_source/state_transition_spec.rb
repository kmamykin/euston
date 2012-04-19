describe 'event source state transition' do
  let(:command)               { ESST1::BuyMilk.v(1).new(id: milk_id).to_hash }
  let(:commit)                { instance.consume command }
  let(:message_class_finder)  { Euston::MessageClassFinder.new Euston::Namespaces.new(ESST1, ESST1, ESST1) }
  let(:milk_id)               { Uuid.generate }

  context 'with a valid state transition' do
    module ESST1
      class ExampleEventSource
        include Euston::EventSource

        commands

        buy_milk do |headers, body|
          transition_to :milk_bought, 1, milk_id: body[:id]
        end

        transitions

        milk_bought do |body|
          @milk_id = body[:milk_id]
        end

        attr_reader :milk_id
      end

      class BuyMilk < Euston::Command
        version 1 do
          validates :id, presence: true
        end
      end

      class MilkBought < Euston::Event
        version 1 do
          validates :milk_id, presence: true
        end
      end
    end

    let(:instance) { ESST1::ExampleEventSource.new message_class_finder }

    describe 'the event source instance after the command was processed' do
      before  { instance.consume command }
      subject { instance }

      its(:milk_id) { should == milk_id }
    end
  end

  context 'with an state transition initiated with invalid data' do
    module ESST1
      class InvalidEventSource
        include Euston::EventSource

        commands

        buy_milk do |headers, body|
          transition_to :milk_bought, 1, something_wrong: body[:id]
        end

        transitions

        milk_bought do |body|
          @milk_id = body[:milk_id]
        end

        attr_reader :milk_id
      end
    end

    let(:instance) { ESST1::InvalidEventSource.new message_class_finder }

    describe 'the event source instance after the command was processed' do
      let(:exceptions)  { [] }

      before do
        begin
          instance.consume command
        rescue Euston::InvalidTransitionStateError => e
          exceptions << e
        end
      end

      subject { exceptions }

      it { should have(1).item }
    end
  end
end
