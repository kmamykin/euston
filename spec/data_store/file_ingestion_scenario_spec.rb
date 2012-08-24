describe 'mongo event store - file ingestion scenario walkthrough', :mongo do
  let(:batch_id)                    { Uuid.generate }
  let(:files)                       { [Uuid.generate, Uuid.generate] }
  let(:global_message_handler_map)  { Euston::GlobalMessageHandlerMap.new namespaces }
  let(:message_bus)                 { Euston::Mongo::MessageBus.new message_class_finder, global_message_handler_map, data_store }
  let(:message_class_finder)        { Euston::MessageClassFinder.new namespaces }
  let(:namespace)                   { Scenarios::FileIngestion }
  let(:namespaces)                  { Euston::Namespaces.new message_handlers: namespace, commands: namespace, events: namespace }
  let(:ns)                          { namespace }

  before do
    global_message_handler_map.inspect_message_handlers

    message = ns::IngestFiles.v(1).new(batch_id: batch_id, files: files).to_hash
    message_bus.handle_message message

    sleep 0.25
  end

  def batch
    history = data_store.get_history Euston::MessageSourceId.new(batch_id, ns::Batch)
    ns::Batch.new(@message_class_finder, history)
  end

  subject { batch }

  it { should_not be_nil }

  describe do
    subject { batch.files[files[0]] }
    it      { should == :ingesting }
  end

  describe do
    subject { batch.files[files[1]] }
    it      { should == :ingesting }
  end

  describe do
    let(:commands) { data_store.get_history(Euston::MessageSourceId.new(batch_id, ns::Batch)).commits.first.commands }

    subject { commands }

    it { should have(2).items }

    describe do
      subject { commands[0][:headers][:correlations] }
      it      { should include batch_id }
    end
  end

  context 'a file is ingested' do
    before do
      message = ns::FileIngested.v(1).new({ correlations: [batch_id] }, { file_id: files[0] }).to_hash
      message_bus.handle_message message
      sleep 0.25
    end

    describe do
      subject { batch.files[files[0]] }
      it      { should == :ingested }
    end

    describe do
      subject { batch.files[files[1]] }
      it      { should == :ingesting }
    end
  end
end
