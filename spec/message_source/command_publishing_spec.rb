describe 'message source command publishing', :golf do
  context 'when the command being published is valid' do
    let(:history) do
      commit = Euston::Commit.new message_source_id: new_starter_message_source_history.message_source_id,
                                  events: [
        namespace::TeeBooked.v(1).new({ sequence: 1 }, course_id: course_id, player_id: player_id, time: time).to_hash
      ]

      Euston::MessageSourceHistory.new id: course_id, commits: [ commit ]
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
    class Scenarios::GolfCourse::MessageSourceWhichPublishesInvalidCommands
      include Euston::MessageSource

      events

      tee_booked :course_id do |headers, body|
        publish_command Scenarios::GolfCourse::CheckForSlowPlay.v(1).new xyz: :abc
      end
    end

    let(:buggy_message_source) do
      type = namespace::MessageSourceWhichPublishesInvalidCommands
      type.new(message_class_finder, new_message_source_history(type)).when(:commit_created) do |commit|
        @commit = commit
      end
    end

    let(:message)     { namespace::TeeBooked.v(1).new(course_id: course_id, player_id: player_id, time: time).to_hash }
    let(:exceptions)  { [] }

    before do
      begin
        buggy_message_source.consume message
      rescue Euston::InvalidCommandError => e
        exceptions << e
      end
    end

    subject { exceptions }

    it { should have(1).item }
  end

  context 'when the message source requests to hear about all events resulting from this command' do
    class Scenarios::GolfCourse::MessageSourceWhichPublishesCommandsWithCorrelatedEventSubscriptions
      include Euston::MessageSource

      events

      tee_booked :course_id do |headers, body|
        publish_command Factory.build(:check_for_slow_play_command), correlated: true
      end
    end

    let(:message_source) do
      type = namespace::MessageSourceWhichPublishesCommandsWithCorrelatedEventSubscriptions
      type.new(message_class_finder, new_message_source_history(type)).when(:commit_created) do |commit|
        @commit = commit
      end
    end

    let(:message) { namespace::TeeBooked.v(1).new(course_id: course_id, player_id: player_id, time: time).to_hash }

    before { message_source.consume message }

    subject { @commit }

    its(:commands) { should have(1).item }

    describe "the first published command's headers" do
      subject { @commit.commands[0][:headers] }

      its([:correlations]) { should have(1).item }
      its([:correlations]) { should include course_id }
    end
  end
end
