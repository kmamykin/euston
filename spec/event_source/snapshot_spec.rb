describe 'event source snapshots', :golf do
  context 'with a event source that has no snapshot capability' do
    let(:history) do
      commit1 = Euston::Commit.new event_source_id: course_id, events: [
        namespace::TeeBooked.v(1).new(course_id: course_id, player_id: player_id, time: time).to_hash
      ]

      commit2 = Euston::Commit.new event_source_id: course_id, sequence: 2, events: [
        namespace::TeeBooked.v(1).new(course_id: course_id, player_id: player_id, time: time + 1000).to_hash
      ]

      Euston::EventSourceHistory.new id: course_id, commits: [commit1, commit2]
    end

    before do
      begin
        starter(history).take_snapshot
      rescue Euston::UnknownSnapshotError => e
        @exception = e
      end
    end

    subject { @exception }

    it { should be_a Euston::UnknownSnapshotError }
  end

  context 'with a event source that has a snapshot capability' do
    let(:history) do
      commit1 = Euston::Commit.new event_source_id: course_id, events: [
        namespace::WarningIssuedForSlowPlay.v(1).new(player_id: :player_1).to_hash
      ]

      commit2 = Euston::Commit.new event_source_id: course_id, sequence: 2, events: [
        namespace::WarningIssuedForSlowPlay.v(1).new(player_id: player_id).to_hash
      ]

      Euston::EventSourceHistory.new id: course_id, commits: [commit1, commit2]
    end

    before  { secretary(history).take_snapshot }
    subject { @snapshot.body }

    its('keys.length') { should == 1 }

    describe do
      subject             { @snapshot.body[:players_with_warnings] }
      its('keys.length')  { should == 2 }
      its([:player_1])    { should == :slow_play }
    end

    describe do
      subject { @snapshot.body[:players_with_warnings][player_id] }
      it      { should == :slow_play }
    end
  end
end
