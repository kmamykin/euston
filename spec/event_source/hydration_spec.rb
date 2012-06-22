describe 'event source hydration', :golf do
  context 'with a event source with no snapshot capability' do
    context 'when the event source is loaded with history containing commits only' do
      class Scenarios::GolfCourse::Scorer
        attr_reader :course_records
      end

      let(:course_record) { 60 + rand(10) }

      let(:history) do
        commit = Euston::Commit.new event_source_id: new_scorer_event_source_id,
                                    events: [
          namespace::CourseRecordBroken.v(1).new(course_id: course_id, player_id: player_id, score: course_record).to_hash
        ]

        Euston::MessageSourceHistory.new id: course_id, commits: [ commit ], sequence: 1
      end

      subject { scorer(history).course_records[course_id] }

      it { should == course_record }
    end

    context 'when the event source is loaded with history containing snapshots' do
      let(:exceptions)  { [] }

      let(:history) do
        commit = Euston::Commit.new event_source_id: new_scorer_event_source_id,
                                    sequence: 2,
                                    events: [
          namespace::CourseRecordBroken.v(1).new(course_id: course_id, player_id: player_id, score: rand(70)).to_hash
        ]

        snapshot = Euston::Snapshot.new event_source_id: commit.event_source_id,
                                        sequence: 1

        Euston::MessageSourceHistory.new id: course_id, commits: [ commit ], sequence: 2, snapshot: snapshot
      end

      before do
        begin
          scorer history
        rescue Euston::UnknownSnapshotError => e
          exceptions << e
        end
      end

      subject { exceptions }

      it { should have(1).item }
    end
  end

  context 'with a snapshotting event source' do
    describe 'when the event source is loaded from a snapshot and no commits' do
      class Scenarios::GolfCourse::Secretary
        attr_reader :players_with_warnings
      end

      let(:snapshot) do
        Euston::Snapshot.new event_source_id: new_secretary_event_source_id,
                             sequence: 1,
                             body: { players_with_warnings: { player_1: :foul_language } }
      end

      let(:history) do
        Euston::MessageSourceHistory.new id: course_id, snapshot: snapshot, sequence: 1
      end

      subject { secretary(history).players_with_warnings }

      its([:player_1]) { should == :foul_language }
    end

    describe 'when the event source is loaded from a snapshot and an commit' do
      let(:snapshot) do
        Euston::Snapshot.new event_source_id: new_secretary_event_source_id,
                             sequence: 1,
                             body: { players_with_warnings: { player_1: :foul_language } }
      end

      let(:history) do
        commit = Euston::Commit.new event_source_id: snapshot.event_source_id, sequence: 2, events: [
          namespace::WarningIssuedForSlowPlay.v(1).new(player_id: player_id).to_hash
        ]

        Euston::MessageSourceHistory.new id: course_id, commits: [commit], sequence: 1, snapshot: snapshot
      end

      subject { secretary(history).players_with_warnings }

      its('keys.length')  { should == 2 }
      its([:player_1])    { should == :foul_language }

      describe do
        subject { secretary(history).players_with_warnings[player_id] }
        it      { should == :slow_play }
      end
    end
  end
end
