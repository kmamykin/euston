describe 'mongo event store - scenario walkthrough', :golf, :mongo do
  let(:player_1)  { Uuid.generate }
  let(:player_2)  { Uuid.generate }

  before do
    # create event source from first event and store commit
    history = Euston::EventSourceHistory.new id: course_id
    secretary = namespace::Secretary.new message_class_finder, history
    secretary.when(:commit_created) { |commit| @commit = commit }

    slow_play_event_1 = namespace::GroupPlayingSlowly.v(1).new(course_id: course_id, player_id: player_1, time: time + rand(100)).to_hash
    secretary.consume slow_play_event_1

    event_store.put_commit @commit

    # reload event source from commits and consume second event and store commit
    commits = event_store.find_commits event_source_id: course_id

    history = Euston::EventSourceHistory.new id: commits.first.event_source_id,
                                             sequence: commits.last.sequence,
                                             commits: commits

    secretary = namespace::Secretary.new message_class_finder, history
    secretary.when(:commit_created) { |commit| @commit = commit }

    slow_play_event_2 = namespace::GroupPlayingSlowly.v(1).new(course_id: course_id, player_id: player_2, time: time + rand(100)).to_hash
    secretary.consume slow_play_event_2

    event_store.put_commit @commit

    sleep 0.5

    # reload snapshottable event source and take snapshot and store snapshot
    stream = event_store.find_streams_to_snapshot(2).first
    commits = event_store.find_commits event_source_id: course_id

    history = Euston::EventSourceHistory.new id: commits.first.event_source_id,
                                             sequence: commits.last.sequence,
                                             commits: commits

    secretary = namespace::Secretary.new message_class_finder, history
    secretary.when(:snapshot_taken) { |snapshot| @snapshot = snapshot }
    secretary.take_snapshot

    event_store.put_snapshot @snapshot
  end

  subject { event_store.get_snapshot course_id }

  its(:event_source_id) { should == course_id }
  its(:sequence)        { should == 2 }
  its(:version)         { should == 1 }
  its(:type)            { should == namespace::Secretary.to_s }

  describe 'the snapshot body' do
    subject { event_store.get_snapshot(course_id).body }
    its([:players_with_warnings]) { should satisfy { |p| p[player_1.to_sym] == :slow_play }}
    its([:players_with_warnings]) { should satisfy { |p| p[player_2.to_sym] == :slow_play }}
  end

  # context 'when a user stores a snapshot' do
  #   let(:commit)              { Factory.build :commit, event_source_id: snapshot.event_source_id }
  #   let(:snapshot)            { Factory.build :snapshot }
  #   let(:retrieved_snapshot)  { event_store.get_snapshot snapshot.event_source_id, snapshot.sequence }

  #   before do
  #     event_store.put_commit commit
  #     sleep 0.5
  #     event_store.put_snapshot snapshot
  #   end

  #   subject { retrieved_snapshot }

  #   its(:event_source_id)         { should == snapshot.event_source_id }
  #   its(:sequence)                { should == snapshot.sequence }
  #   its(:type)                    { should == snapshot.type }
  #   its(:version)                 { should == snapshot.version }

  #   describe 'contained body' do
  #     subject { retrieved_snapshot.body }
  #     its(:keys)  { should satisfy { |keys| keys.length == snapshot.body.keys.length && keys.all? { |key| snapshot.body.symbolize_keys.keys.include? key.to_sym } } }
  #     it          { should satisfy { |body| body.keys.all? { |key| snapshot.body.symbolize_keys[key.to_sym] == body[key] } } }
  #   end

  #   describe 'contained idempotence message ids' do
  #     subject { retrieved_snapshot.idempotence_message_ids }
  #     it      { should have(snapshot.idempotence_message_ids.length).items }
  #     it      { should satisfy { |ids| ids.all? { |id| snapshot.idempotence_message_ids.include? id } } }
  #   end
  # end
end
