describe 'command handler', :golf do
  let(:metadata)  { namespace::WeatherStation.message_map.to_hash }

  subject { metadata }

  its([:initialization])  { should be_nil }
  its([:events])          { should == {} }
  its([:snapshots])       { should == {} }
  its([:transitions])     { should == {} }

  describe 'command metadata' do
    let(:command_metadata) { metadata[:commands] }

    subject { command_metadata }

    its([:log_temperature]) { should be_a Hash }

    describe 'versions' do
      subject { command_metadata[:log_temperature] }

      its([1]) { should be_a Hash }

      describe 'version 1' do
        subject { command_metadata[:log_temperature][1] }

        its([:identifier])    { should be_nil }
        its([:message_type])  { should == :command }
        its([:message_class]) { should == 'LogTemperature_v1' }
      end
    end
  end
end
