describe 'message source command invocation', :golf do
  context 'a command is consumed which causes a transition to a new state' do
    let(:command) { namespace::BookTee.v(1).new(course_id: course_id, player_id: player_id, time: time).to_hash }

    before { starter(new_starter_message_source_history).consume command }

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

        its([:type])    { should == :tee_booked }
        its([:version]) { should == 1 }
      end

      describe 'body' do
        subject { @commit.events[0][:body] }

        its([:course_id]) { should == course_id }
        its([:player_id]) { should == player_id }
        its([:time])      { should == time }
      end
    end
  end

  context 'a command is consumed which contains correlation ids' do
    let(:command)           { namespace::BookTee.v(1).new(command_headers, command_body).to_hash }
    let(:command_body)      { Factory.build(:book_tee_command).to_hash[:body] }
    let(:command_headers)   { { correlations: [correlation_id_1, correlation_id_2] } }
    let(:correlation_id_1)  { Uuid.generate }
    let(:correlation_id_2)  { Uuid.generate }

    before { starter(new_starter_message_source_history).consume command }

    subject { @commit.events[0][:headers] }

    its([:correlations]) { should include correlation_id_1 }
    its([:correlations]) { should include correlation_id_2 }
  end
end
