describe 'mongo event store - scenario walkthrough', :golf, :mongo do
  let(:global_message_handler_map)  { Euston::GlobalMessageHandlerMap.new namespaces }
  let(:message_bus)                 { Euston::Mongo::MessageBus.new message_class_finder, global_message_handler_map, data_store }
  let(:player_1)                    { Uuid.generate }
  let(:player_2)                    { Uuid.generate }

  before do
    global_message_handler_map.inspect_message_handlers

    message = namespace::GroupPlayingSlowly.v(1).new(course_id: course_id, player_id: player_1, time: time + rand(100)).to_hash
    message_bus.handle_message message

    message = namespace::GroupPlayingSlowly.v(1).new(course_id: course_id, player_id: player_2, time: time + rand(100)).to_hash
    message_bus.handle_message message

    sleep 0.25

    @stream = data_store.find_streams_to_snapshot(2).find { |stream| stream.message_source_id.id == "george" }
    history = data_store.get_history @stream.message_source_id

    Euston::ConstantLoader.new.when(:hit) do |klass|
      klass.new(message_class_finder, history).when(:snapshot_taken) do |snapshot|
        data_store.put_snapshot snapshot
      end.take_snapshot
    end.load history.message_source_id.type
  end

  subject { data_store.get_snapshot @stream.message_source_id }

  its(:sequence)        { should == 2 }
  its(:version)         { should == 1 }

  describe 'the snashot message source id' do
    subject { data_store.get_snapshot(@stream.message_source_id).message_source_id }

    its(:id)    { should == "george" }
    its(:type)  { should == namespace::Secretary.to_s }
  end

  describe 'the snapshot body' do
    subject { data_store.get_snapshot(@stream.message_source_id).body }

    its([:players_with_warnings]) { should satisfy { |p| p[player_1.to_sym] == :slow_play }}
    its([:players_with_warnings]) { should satisfy { |p| p[player_2.to_sym] == :slow_play }}
  end
end
