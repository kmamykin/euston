describe 'event source historical versioning', :golf do
  context 'a new event source generates a commit' do
    let(:command) { namespace::BookTee.v(1).new(course_id: course_id, player_id: player_id, time: time).to_hash }

    before  { starter(new_event_source_history).consume command }

    subject { @commit }

    its(:sequence) { should == 1 }
  end

  context 'an event source that has already generated 1 commit receives another command' do
    let(:history) do
      commit = Euston::Commit.new event_source_id: course_id, events: [
        namespace::TeeBooked.v(1).new({ sequence: 1 }, course_id: course_id, player_id: player_id, time: time).to_hash
      ]

      Euston::EventSourceHistory.new id: course_id, commits: [ commit ]
    end

    let(:command) { namespace::CancelTeeBooking.v(1).new(course_id: course_id, player_id: player_id, time: time).to_hash }

    before  { starter(history).consume command }

    subject { @commit }

    its(:sequence) { should == 2 }
  end
end
