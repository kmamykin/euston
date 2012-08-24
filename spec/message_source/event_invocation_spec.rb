describe 'message source event invocation', :golf do
  context 'an event is consumed which causes a transition to a new state' do
    let(:event) { namespace::GroupPlayingSlowly.v(1).new(course_id: course_id, player_id: player_id, time: time).to_hash }

    before  { secretary(new_secretary_message_source_history).consume event }

    subject { @commit }

    its(:origin)  { should == event }
    its(:events)  { should have(1).item }

    describe 'the first event in the event stream' do
      subject { @commit.events[0] }

      it              { should be_a Hash }
      its([:headers]) { should be_a Hash }
      its([:body])    { should be_a Hash }

      describe 'headers' do
        subject { @commit.events[0][:headers] }

        its([:type])    { should == :warning_issued_for_slow_play }
        its([:version]) { should == 1 }
      end

      describe 'body' do
        subject { @commit.events[0][:body] }

        its([:player_id]) { should == player_id }
      end
    end
  end

  context 'an event is consumed which contains correlation ids' do
    let(:event)             { namespace::GroupPlayingSlowly.v(1).new(event_headers, event_body).to_hash }
    let(:event_body)        { Factory.build(:group_playing_slowly_event).to_hash[:body] }
    let(:event_headers)     { { correlations: [correlation_id_1, correlation_id_2] } }
    let(:correlation_id_1)  { Uuid.generate }
    let(:correlation_id_2)  { Uuid.generate }

    before  { secretary(new_secretary_message_source_history).consume event }

    subject { @commit.events[0][:headers] }

    its([:correlations]) { should include correlation_id_1 }
    its([:correlations]) { should include correlation_id_2 }
  end
end
