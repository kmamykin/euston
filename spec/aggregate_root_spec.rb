require File.expand_path("../spec_helper", __FILE__)

module Euston
  describe 'aggregate root' do
    let(:aggregate)       { Sample::Widget.new }
    let(:command_headers) { CommandHeaders.new id: Euston.uuid.generate, type: 'create_widget', version: 1 }
    let(:command_body)    { { :id => Euston.uuid.generate } }

    before do
      aggregate.consume_command command_headers, command_body
    end

    subject { aggregate }

    context 'commmand consumption' do
      its(:uncommitted_events)  { should have(1).item }
      
      describe 'the uncommitted headers' do
        subject { aggregate.uncommitted_headers }
        
        its([:source_message_type]) { should == :command }

        describe 'the source message' do
          subject { aggregate.uncommitted_headers[:source_message] }

          its([:headers]) { should == command_headers }
          its([:body])    { should == command_body }
        end
      end
    end

    context 'duplicate command consumption' do
      subject do 
        stream = OpenStruct.new.tap do |s| 
          s.committed_headers = { source_message_type: :command, 
                                  source_message: { headers: command_headers, body: command_body } }
          s.committed_events = aggregate.uncommitted_events
        end

        aggregate2 = Sample::Widget.hydrate stream
        aggregate2.consume_command command_headers, command_body
        aggregate2
      end

      its(:uncommitted_events) { should have(0).items }
    end
  end
end
