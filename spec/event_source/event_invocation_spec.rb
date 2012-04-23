describe 'event source event invocation', :golf do
  context 'an event is consumed which causes a transition to a new state' do
    let(:event) { namespace::GroupPlayingSlowly.v(1).new(course_id: course_id, player_id: player_id, time: time).to_hash }

    before  { secretary.consume event }

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
end
