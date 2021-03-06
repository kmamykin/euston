describe 'global message handler map' do
  context 'with an message source containing an unverifiable command' do
    module GMM2
      class MessageSourceWithUnverifiableCommand
        include Euston::MessageSource

        commands

        unknown_command 1 do |headers, body|
        end
      end
    end

    let(:exceptions)  { [] }
    let(:map)         { Euston::GlobalMessageHandlerMap.new Euston::Namespaces.new(message_handlers: GMM2) }

    before do
      begin
        map.inspect_message_handlers
      rescue Euston::UnverifiableMessageSource => e
        exceptions << e
      end
    end

    subject { exceptions[0] }

    its(:to_s) { should include 'unknown_command' }
    its(:to_s) { should include 'version 1' }
  end

  context 'with an message source containing a verifiable command and an unverifiable command' do
    module GMM3
      class MessageSourceWithUnverifiableCommand
        include Euston::MessageSource

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
    let(:map)         { Euston::GlobalMessageHandlerMap.new Euston::Namespaces.new(message_handlers: GMM3, commands: GMM3) }

    before do
      begin
        map.inspect_message_handlers
      rescue Euston::UnverifiableMessageSource => e
        exceptions << e
      end
    end

    subject { exceptions[0] }

    its(:to_s) { should include 'command_b' }
    its(:to_s) { should include 'version 2' }
  end

  context 'with an message source containing an unverifiable event' do
    module GMM4
      class MessageSourceWithUnverifiableEvent
        include Euston::MessageSource

        events

        unknown_event 3 do |headers, body|
        end
      end
    end

    let(:exceptions)  { [] }
    let(:map)         { Euston::GlobalMessageHandlerMap.new Euston::Namespaces.new(message_handlers: GMM4) }

    before do
      begin
        map.inspect_message_handlers
      rescue Euston::UnverifiableMessageSource => e
        exceptions << e
      end
    end

    subject { exceptions[0] }

    its(:to_s) { should include 'unknown_event' }
    its(:to_s) { should include 'version 3' }
  end

  context 'with an message source containing a verifiable event and an unverifiable event' do
    module GMM5
      class MessageSourceWithUnverifiableEvent
        include Euston::MessageSource

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
    let(:map)         { Euston::GlobalMessageHandlerMap.new Euston::Namespaces.new(message_handlers: GMM5, events: GMM5) }

    before do
      begin
        map.inspect_message_handlers
      rescue Euston::UnverifiableMessageSource => e
        exceptions << e
      end
    end

    subject { exceptions[0] }

    its(:to_s) { should include 'event_b' }
    its(:to_s) { should include 'version 1' }
  end

  context 'with an message source containing an unverifiable transition' do
    module GMM6
      class MessageSourceWithUnverifiableTransition
        include Euston::MessageSource

        transitions

        unknown_transition 2 do |body|
        end
      end
    end

    let(:exceptions)  { [] }
    let(:map)         { Euston::GlobalMessageHandlerMap.new Euston::Namespaces.new(message_handlers: GMM6, events: GMM6) }

    before do
      begin
        map.inspect_message_handlers
      rescue Euston::UnverifiableMessageSource => e
        exceptions << e
      end
    end

    subject { exceptions[0] }

    its(:to_s) { should include 'unknown_transition' }
    its(:to_s) { should include 'version 2' }
  end

  context 'with an message source containing a verifiable event and an unverifiable event' do
    module GMM7
      class MessageSourceWithUnverifiableTransition
        include Euston::MessageSource

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
    let(:map)         { Euston::GlobalMessageHandlerMap.new Euston::Namespaces.new(message_handlers: GMM7, events: GMM7) }

    before do
      begin
        map.inspect_message_handlers
      rescue Euston::UnverifiableMessageSource => e
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
      let(:map)         { Euston::GlobalMessageHandlerMap.new Euston::Namespaces.new(commands: GMM8) }

      before do
        map.inspect_message_handlers

        begin
          map.find_message_handlers command
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
      class RoutableMessageSource
        include Euston::MessageSource

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
      let(:command)     { GMM9::WalkDog.v(1).new(dog_id: dog_id).to_hash }
      let(:dog_id)      { Uuid.generate }
      let(:exceptions)  { [] }
      let(:map)         { Euston::GlobalMessageHandlerMap.new Euston::Namespaces.new(message_handlers: GMM9, commands: GMM9, events: GMM9) }
      let(:commits)     { [] }
      let(:discovered)  { map.find_message_handlers command }

      before  { map.inspect_message_handlers }
      subject { discovered }

      it { should have(1).item }

      describe 'discovered handler' do
        subject           { discovered[0] }
        its([:category])  { should == :message_source }
        its([:handler])   { should == GMM9::RoutableMessageSource }
      end
    end
  end
end
