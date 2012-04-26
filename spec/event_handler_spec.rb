describe 'event handler', :golf do
  let(:metadata)  { namespace::EmailQueue.message_map.to_hash }

  subject { metadata }

  its([:initialization])  { should be_nil }
  its([:commands])          { should == {} }
  its([:snapshots])       { should == {} }
  its([:transitions])     { should == {} }

  describe 'event metadata' do
    let(:event_metadata) { metadata[:events] }

    subject { event_metadata }

    its([:warning_issued_for_slow_play]) { should be_a Hash }

    describe 'versions' do
      subject { event_metadata[:warning_issued_for_slow_play] }

      its([1]) { should be_a Hash }

      describe 'version 1' do
        subject { event_metadata[:warning_issued_for_slow_play][1] }

        its([:identifier])    { should == :id }
        its([:message_type])  { should == :event }
        its([:message_class]) { should == 'WarningIssuedForSlowPlay_v1' }
      end
    end
  end
end
