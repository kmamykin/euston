describe 'mongo event store - commits', :golf, :mongo do
  let(:saved_commits) { data_store.find_commits }

  context 'given an empty event store' do
    context 'when the user attempts to find all commits' do
      subject { saved_commits }
      it      { should have(0).items }
    end

    context 'when the user saves a commit' do
      let(:commit) { Factory.build :commit }

      before  { data_store.put_commit commit }
      subject { saved_commits }
      it      { should have(1).item }

      describe 'the saved commit' do
        subject { saved_commits.first }

        its('message_source_id.id')   { should == commit.message_source_id.id }
        its('message_source_id.type') { should == commit.message_source_id.type }
        its('sequence')             { should == 1 }
        its('timestamp.to_f')       { should == commit.timestamp.to_f }

        describe 'the origin of the commit' do
          subject { RecursiveOpenStruct.new(saved_commits.first.origin) }

          its('headers.id')       { should == commit.origin[:headers][:id] }
          its('headers.type')     { should == commit.origin[:headers][:type] }
          its('headers.version')  { should == commit.origin[:headers][:version] }

          its('body.course_id')   { should == commit.origin[:body][:course_id] }
          its('body.player_id')   { should == commit.origin[:body][:player_id] }
          its('body.time')        { should == commit.origin[:body][:time] }
        end

        describe 'the contained commands' do
          subject { saved_commits.first.commands }
          it      { should have(1).item }

          describe 'the first command' do
            subject { saved_commits.first.commands.map_to(RecursiveOpenStruct).first }

            its('headers.id')       { should == commit.commands[0][:headers][:id] }
            its('headers.type')     { should == commit.commands[0][:headers][:type] }
            its('headers.version')  { should == commit.commands[0][:headers][:version] }

            its('body.course_id')   { should == commit.commands[0][:body][:course_id] }
            its('body.player_id')   { should == commit.commands[0][:body][:player_id] }
            its('body.time')        { should == commit.commands[0][:body][:time] }
          end
        end

        describe 'the contained events' do
          subject { saved_commits.first.events }
          it      { should have(1).item }

          describe 'the first event' do
            subject { saved_commits.first.events.map_to(RecursiveOpenStruct).first }

            its('headers.id')       { should == commit.events[0][:headers][:id] }
            its('headers.type')     { should == commit.events[0][:headers][:type] }
            its('headers.version')  { should == commit.events[0][:headers][:version] }

            its('body.course_id')   { should == commit.events[0][:body][:course_id] }
            its('body.player_id')   { should == commit.events[0][:body][:player_id] }
            its('body.time')        { should == commit.events[0][:body][:time] }
          end
        end
      end

      context 'and the user looks for undispatched commits' do
        let(:dispatcher_id)         { Uuid.generate }
        let(:undispatched_commits)  { data_store.find_dispatchable_commits dispatcher_id }

        before  { data_store.take_ownership_of_undispatched_commits dispatcher_id }
        subject { undispatched_commits }
        it      { should have(1).item }

        describe 'the first commit' do
          subject   { undispatched_commits.first }
          its(:id)  { should == commit.id }
        end

        context 'and the user marks the commit as dispatched' do
          before  { data_store.mark_commits_as_dispatched undispatched_commits }
          subject { data_store.find_dispatchable_commits dispatcher_id }
          it      { should have(0).items }
        end
      end

      context 'and the user looks for snapshottable streams' do
        let(:snapshottable_streams) { data_store.find_streams_to_snapshot 1 }
        before  { sleep 0.5 }   # stream document update occurs asynchronously
        subject { snapshottable_streams }
        it      { should have(1).item }
      end

      context 'and then the user tries to resave the commit' do
        let(:exceptions) { [] }

        before do
          begin
            data_store.put_commit saved_commits.first
          rescue => e
            exceptions << e
          end
        end

        subject { exceptions.first }
        it      { should be_a Euston::Mongo::DuplicateCommitError }
      end
    end

    context 'when the user tries to save the same commit twice in succession' do
      let(:commit)      { Factory.build :commit }
      let(:exceptions)  { [] }

      before do
        data_store.put_commit commit

        begin
          data_store.put_commit commit
        rescue => e
          exceptions << e
        end
      end

      subject { exceptions.first }
      it      { should be_a Euston::Mongo::DuplicateCommitError }
    end
  end

  context 'given an event store that contains several commits' do
    let(:message_source_id1)  { Factory.build(:message_source_id) }
    let(:message_source_id2)  { Factory.build(:message_source_id) }
    let(:commit_1_1) { Factory.build :commit, message_source_id: message_source_id1, sequence: 1 }
    let(:commit_1_2) { Factory.build :commit, message_source_id: message_source_id1, sequence: 2 }
    let(:commit_2_1) { Factory.build :commit, message_source_id: message_source_id2, sequence: 1 }
    let(:commit_1_3) { Factory.build :commit, message_source_id: message_source_id1, sequence: 3 }
    let(:commit_2_2) { Factory.build :commit, message_source_id: message_source_id2, sequence: 2 }
    let(:commit_1_4) { Factory.build :commit, message_source_id: message_source_id1, sequence: 4 }

    before do
      data_store.put_commit commit_1_1
      data_store.put_commit commit_1_2
      data_store.put_commit commit_2_1
      data_store.put_commit commit_1_3
      data_store.put_commit commit_2_2
      data_store.put_commit commit_1_4
    end

    context 'when the user requests all the commits for a particular event source' do
      let(:commits_for_event_source_2) { data_store.find_commits message_source_id: message_source_id2 }

      subject { commits_for_event_source_2 }
      it      { should have(2).items }

      describe 'the first commit' do
        subject   { commits_for_event_source_2[0] }
        its(:id)  { should == commit_2_1.id }
      end

      describe 'the second commit' do
        subject   { commits_for_event_source_2[1] }
        its(:id)  { should == commit_2_2.id }
      end
    end

    context 'when the user requests a range of commits for a particular event source' do
      let(:commits_for_event_source_1) do
        data_store.find_commits message_source_id: message_source_id1, min_sequence: 2, max_sequence: 3
      end

      subject { commits_for_event_source_1 }
      it      { should have(2).items }

      describe 'the first commit' do
        subject   { commits_for_event_source_1[0] }
        its(:id)  { should == commit_1_2.id }
      end

      describe 'the second commit' do
        subject   { commits_for_event_source_1[1] }
        its(:id)  { should == commit_1_3.id }
      end
    end
  end

  context 'given an event store that contains a lot of commits for a single event source' do
    let(:message_source_id) { Factory.build(:message_source_id) }

    before do
      large_body = { values: Array.new(100) { Uuid.generate } }

      101.times do |i|
        commit = Factory.build :commit, message_source_id: message_source_id, sequence: i
        data_store.put_commit commit
      end
    end

    subject { data_store.get_history message_source_id }

    its(:commits) { should have(101).items }
  end
end
