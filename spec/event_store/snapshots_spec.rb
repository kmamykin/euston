describe 'mongo event store - snapshots', :golf, :mongo do
  context 'when a user stores a snapshot' do
    let(:commit)              { Factory.build :commit, event_source_id: snapshot.event_source_id }
    let(:snapshot)            { Factory.build :snapshot }
    let(:retrieved_snapshot)  { event_store.get_snapshot snapshot.event_source_id, snapshot.sequence }

    before do
      event_store.put_commit commit
      sleep 0.5
      event_store.put_snapshot snapshot
    end

    subject { retrieved_snapshot }

    its(:event_source_id)         { should == snapshot.event_source_id }
    its(:sequence)                { should == snapshot.sequence }
    its(:type)                    { should == snapshot.type }
    its(:version)                 { should == snapshot.version }

    describe 'contained body' do
      subject { retrieved_snapshot.body }
      its(:keys)  { should satisfy { |keys| keys.length == snapshot.body.keys.length && keys.all? { |key| snapshot.body.symbolize_keys.keys.include? key.to_sym } } }
      it          { should satisfy { |body| body.keys.all? { |key| snapshot.body.symbolize_keys[key.to_sym] == body[key] } } }
    end

    describe 'contained idempotence message ids' do
      subject { retrieved_snapshot.idempotence_message_ids }
      it      { should have(snapshot.idempotence_message_ids.length).items }
      it      { should satisfy { |ids| ids.all? { |id| snapshot.idempotence_message_ids.include? id } } }
    end
  end

  context 'when a user retrieves a snapshot using a particular sequence number' do
    let(:event_source_id)   { Uuid.generate }

    let(:too_old_snapshot)  { Factory.build :snapshot, event_source_id: event_source_id, sequence: 1 }
    let(:correct_snapshot)  { Factory.build :snapshot, event_source_id: event_source_id, sequence: 3, body: { val: rand(1000) } }
    let(:too_new_snapshot)  { Factory.build :snapshot, event_source_id: event_source_id, sequence: 5 }

    let(:commit_1)          { Factory.build :commit, event_source_id: event_source_id, sequence: 1 }
    let(:commit_2)          { Factory.build :commit, event_source_id: event_source_id, sequence: 3 }
    let(:commit_3)          { Factory.build :commit, event_source_id: event_source_id, sequence: 5 }

    let(:retrieved_snapshot) { event_store.get_snapshot event_source_id, too_new_snapshot.sequence - 1 }

    before do
      event_store.put_commit commit_1
      event_store.put_commit commit_2
      event_store.put_commit commit_3

      sleep 0.5

      event_store.put_snapshot too_old_snapshot
      event_store.put_snapshot correct_snapshot
      event_store.put_snapshot too_new_snapshot
    end

    subject { retrieved_snapshot }

    its(:sequence)  { should == correct_snapshot.sequence }

    describe 'the contained body' do
      subject     { retrieved_snapshot.body }
      its([:val]) { should == correct_snapshot.body[:val] }
    end
  end

  context 'when a snapshot has been added to the most recent commit of a stream' do
    let(:event_source_id)     { Uuid.generate }
    let(:oldest_commit)       { Factory.build :commit, event_source_id: event_source_id, sequence: 1 }
    let(:next_oldest_commit)  { Factory.build :commit, event_source_id: event_source_id, sequence: 3 }
    let(:newest_commit)       { Factory.build :commit, event_source_id: event_source_id, sequence: 5 }
    let(:snapshot)            { Factory.build :snapshot, event_source_id: event_source_id, sequence: 5, body: { val: rand(1000) } }

    before do
      event_store.put_commit oldest_commit
      event_store.put_commit next_oldest_commit
      event_store.put_commit newest_commit

      sleep 0.5

      event_store.put_snapshot snapshot
    end

    subject { event_store.find_streams_to_snapshot 1 }

    it { should have(0).items }
  end

  context 'when a user adds a commit after a snapshot' do
    let(:within_threshold)    { 2 }
    let(:over_threshold)      { 3 }
    let(:snapshot_data)       { { val: rand(1000) } }
    let(:oldest_commit)       { Factory.build :commit, event_source_id: event_source_id, sequence: 1 }
    let(:next_oldest_commit)  { Factory.build :commit, event_source_id: event_source_id, sequence: 3 }
    let(:newest_commit)       { Factory.build :commit, event_source_id: event_source_id, sequence: 5 }
    let(:snapshot)            { Factory.build :snapshot, event_source_id: event_source_id, sequence: 3, body: { val: rand(1000) } }

    before do
      event_store.put_commit oldest_commit
      event_store.put_commit next_oldest_commit
      sleep 0.5
      event_store.put_snapshot snapshot
      event_store.put_commit newest_commit

      sleep 0.5
    end

    describe 'within threshold' do
      subject { event_store.find_streams_to_snapshot 1 }
      it      { should have(1).item }
    end

    describe 'over threshold' do
      subject { event_store.find_streams_to_snapshot 2 }
      it      { should have(0).items }
    end
 end
end
