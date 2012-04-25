describe 'event source command publishing', :golf do
  context 'when the command being published is valid' do
    let(:history) do
      commit = Euston::Commit.new event_source_id: course_id, events: [
        namespace::TeeBooked.v(1).new(course_id: course_id, player_id: player_id, time: time).to_hash
      ]

      Euston::EventSourceHistory.new commits: [ commit ]
    end

    let(:command) { namespace::StartGroup.v(1).new(course_id: course_id, player_id: player_id, time: time).to_hash }

    before { starter(history).consume command }

    subject { @commit }

    its(:commands) { should have(1).item }

    describe "the first published command's headers" do
      subject { @commit.commands[0][:headers] }

      its([:type])    { should == :check_for_slow_play }
      its([:version]) { should == 1 }
    end

    describe "the first published command's body" do
      subject { @commit.commands[0][:body] }

      its([:course_id]) { should == course_id }
      its([:player_id]) { should == player_id }
      its([:time])      { should == time }
    end
  end

  context 'when the command being published is invalid' do
    class Scenarios::GolfCourse::EventSourceWhichPublishesInvalidCommands
      include Euston::EventSource

      commands

      book_tee :course_id do |headers, body|
        publish_command Scenarios::GolfCourse::CheckForSlowPlay.v(1).new xyz: :abc
      end
    end

    let(:buggy_event_source) do
      namespace::EventSourceWhichPublishesInvalidCommands.new(message_class_finder).when(:commit_created) do |commit|
        @commit = commit
      end
    end

    let(:command)     { namespace::BookTee.v(1).new(course_id: course_id, player_id: player_id, time: time).to_hash }
    let(:exceptions)  { [] }

    before do
      begin
        buggy_event_source.consume command
      rescue Euston::InvalidCommandError => e
        exceptions << e
      end
    end

    subject { exceptions }

    it { should have(1).item }
  end
end
