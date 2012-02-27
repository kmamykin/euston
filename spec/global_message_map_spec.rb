describe 'global message map' do
  context 'with an event source containing an unverifiable command' do
    module GMM2
      class EventSourceWithUnverifiableCommand
        include Euston::EventSource

        commands

        unknown_command 1 do |headers, body|
        end
      end
    end

    let(:exceptions)  { [] }
    let(:map)         { Euston::GlobalMessageMap.new Euston::Namespaces.new(GMM2) }

    before do
      begin
        map.inspect_event_sources
      rescue Euston::UnverifiableEventSource => e
        exceptions << e
      end
    end

    subject { exceptions[0] }

    its(:to_s) { should include 'unknown_command' }
    its(:to_s) { should include 'version 1' }
  end

  context 'with an event source containing a verifiable command and an unverifiable command' do
    module GMM3
      class EventSourceWithUnverifiableCommand
        include Euston::EventSource

        commands

        command_a 1 do |headers, body|
        end

        command_b 2 do |headers, body|
        end
      end

      class CommandA < Euston::Command
        version 1 do
          validates :id, presence: true
        end
      end
    end

    let(:exceptions)  { [] }
    let(:map)         { Euston::GlobalMessageMap.new Euston::Namespaces.new(GMM3, GMM3) }

    before do
      begin
        map.inspect_event_sources
      rescue Euston::UnverifiableEventSource => e
        exceptions << e
      end
    end

    subject { exceptions[0] }

    its(:to_s) { should include 'command_b' }
    its(:to_s) { should include 'version 2' }
  end

  context 'with an event source containing an unverifiable event' do
    module GMM4
      class EventSourceWithUnverifiableEvent
        include Euston::EventSource

        events

        unknown_event 3 do |headers, body|
        end
      end
    end

    let(:exceptions)  { [] }
    let(:map)         { Euston::GlobalMessageMap.new Euston::Namespaces.new(GMM4) }

    before do
      begin
        map.inspect_event_sources
      rescue Euston::UnverifiableEventSource => e
        exceptions << e
      end
    end

    subject { exceptions[0] }

    its(:to_s) { should include 'unknown_event' }
    its(:to_s) { should include 'version 3' }
  end

  context 'with an event source containing a verifiable event and an unverifiable event' do
    module GMM5
      class EventSourceWithUnverifiableEvent
        include Euston::EventSource

        events

        event_a 2 do |headers, body|
        end

        event_b 1 do |headers, body|
        end
      end

      class EventA < Euston::Event
        version 2 do
          validates :id, presence: true
        end
      end
    end

    let(:exceptions)  { [] }
    let(:map)         { Euston::GlobalMessageMap.new Euston::Namespaces.new(GMM5, [], GMM5) }

    before do
      begin
        map.inspect_event_sources
      rescue Euston::UnverifiableEventSource => e
        exceptions << e
      end
    end

    subject { exceptions[0] }

    its(:to_s) { should include 'event_b' }
    its(:to_s) { should include 'version 1' }
  end

  context 'with an event source containing an unverifiable transition' do
    module GMM6
      class EventSourceWithUnverifiableTransition
        include Euston::EventSource

        transitions

        unknown_transition 2 do |body|
        end
      end
    end

    let(:exceptions)  { [] }
    let(:map)         { Euston::GlobalMessageMap.new Euston::Namespaces.new(GMM6, [], GMM6) }

    before do
      begin
        map.inspect_event_sources
      rescue Euston::UnverifiableEventSource => e
        exceptions << e
      end
    end

    subject { exceptions[0] }

    its(:to_s) { should include 'unknown_transition' }
    its(:to_s) { should include 'version 2' }
  end

  context 'with an event source containing a verifiable event and an unverifiable event' do
    module GMM7
      class EventSourceWithUnverifiableTransition
        include Euston::EventSource

        transitions

        transition_a 1 do |headers, body|
        end

        transition_b 4 do |headers, body|
        end
      end

      class TransitionA < Euston::Event
        version 1 do
          validates :id, presence: true
        end
      end
    end

    let(:exceptions)  { [] }
    let(:map)         { Euston::GlobalMessageMap.new Euston::Namespaces.new(GMM7, [], GMM7) }

    before do
      begin
        map.inspect_event_sources
      rescue Euston::UnverifiableEventSource => e
        exceptions << e
      end
    end

    subject { exceptions[0] }

    its(:to_s) { should include 'transition_b' }
    its(:to_s) { should include 'version 4' }
  end

  context 'with an unroutable command' do
    module GMM8
      class WalkDog < Euston::Command
        version 1 do
          validates :dog_id, presence: true
        end
      end
    end

    describe 'when a command handler is sought' do
      let(:command)     { GMM8::WalkDog.v(1).new(dog_id: Uuid.generate).to_hash }
      let(:exceptions)  { [] }
      let(:map)         { Euston::GlobalMessageMap.new Euston::Namespaces.new([], GMM8) }

      before do
        map.inspect_event_sources
        
        begin
          map.find_command_handler command
        rescue Euston::UnroutableMessageError => e
          exceptions << e
        end
      end

      subject { exceptions }

      it { should have(1).item }
    end
  end

  context 'with a routable command' do
    module GMM9
      class RoutableEventSource
        include Euston::EventSource

        commands

        walk_dog 1 do |headers, body|
          transition_to :dog_walked, 1, body
        end

        transitions

        dog_walked 1 do |body|
        end
      end

      class WalkDog < Euston::Command
        version 1 do
          validates :dog_id, presence: true
        end
      end

      class DogWalked < Euston::Event
        version 1 do
          validates :dog_id, presence: true
        end
      end
    end

    describe 'when a command handler is sought' do
      let(:command)       { GMM9::WalkDog.v(1).new(dog_id: dog_id).to_hash }
      let(:dog_id)        { Uuid.generate }
      let(:exceptions)    { [] }
      let(:map)           { Euston::GlobalMessageMap.new Euston::Namespaces.new(GMM9, GMM9, GMM9) }
      let(:event_streams) { [] }
      
      before  { map.inspect_event_sources }
      subject { map.find_command_handler command }

      it { should == GMM9::RoutableEventSource }
    end
  end
end
