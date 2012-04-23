describe 'event source idempotence', :golf do
  subject { @commit }

  context "with an event source loaded solely from commits which already include the command's id" do
    let(:score)   { 60 + rand(10) }
    let(:command) { namespace::LogScore.v(1).new(course_id: course_id, player_id: player_id, score: score, time: time).to_hash }

    let(:history) do
      commit = Euston::Commit.new command, 1, [
        namespace::ScoreLogged.v(1).new(course_id: course_id, player_id: player_id, score: score, time: time).to_hash
      ]

      Euston::EventSourceHistory.new commits: [ commit ]
    end

    before  { scorer(history).consume command }

    it { should be_empty }
  end

  context "with an event source loaded solely from snapshots which already include the command's id" do
    let(:event) { namespace::WarningIssuedForSlowPlay.v(1).new(player_id: player_id).to_hash }

    let(:snapshot) do
      Euston::Snapshot.new namespace::Secretary, 1, 1, [event[:headers][:id]], players_with_warnings: Hash[player_id, :slow_play]
    end

    let(:history) { Euston::EventSourceHistory.new snapshot: snapshot }

    before { secretary(history).consume event }

    it { should be_empty }
  end
end
