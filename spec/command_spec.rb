describe 'commands' do
  class SomeExample < Euston::Command
    version 1 do
      validates :xyz, presence: true
    end

    version 2 do
      validates :abc, presence: true
      validates :xyz, presence: true
    end
  end

  let(:hash)    { command.to_hash }
  let(:headers) { hash[:headers] }
  let(:body)    { hash[:body] }
  let(:xyz)     { (1..100).to_a.sample }

  context 'a valid command is created with no assigned metadata' do
    let(:command) { SomeExample.v(1).new xyz: xyz }

    describe 'the headers' do
      subject { headers }

      its([:id])      { should match /\A([0-9a-fA-F]){8}-(([0-9a-fA-F]){4}-){3}([0-9a-fA-F]){12}\z/ }
      its([:type])    { should == :some_example }
      its([:version]) { should == 1 }
    end

    describe 'the body' do
      subject { body }

      its([:xyz]) { should == xyz }
    end
  end

  context 'a valid command is created with an assigned id' do
    let(:command) { SomeExample.v(2).headers(id: id).body(abc: abc, xyz: xyz) }
    let(:id)      { Uuid.generate }
    let(:abc)     { (2..10).to_a.sample }

    describe 'the headers' do
      subject { headers }

      its([:id])      { should == id }
      its([:type])    { should == :some_example }
      its([:version]) { should == 2 }
    end

    describe 'the body' do
      subject { body }

      its([:abc]) { should == abc }
      its([:xyz]) { should == xyz }
    end
  end

  context 'an command is created with an invalid id and an invalid body' do
    let(:command)   { SomeExample.v(2).headers(id: 123).body }

    describe 'validity' do
      subject { command.valid? }

      it { should be_false }
    end

    describe 'errors' do
      before  { command.valid? }
      subject { command.errors }

      its([:abc]) { should == ["can't be blank"] }
      its([:xyz]) { should == ["can't be blank"] }

      its([:base])  { should == ["Id specified in the headers of a SomeExample message must be a string Uuid"] }
    end
  end

  context 'a command is created from a hash that has keys which do not match the attributes on the message' do
    let(:command)   { SomeExample.v(2).new xyz: 1, abc: 2, nonono: 3 }

    subject { command.to_hash[:body] }

    its([:abc])     { should == 2 }
    its([:nonono])  { should be_nil }
    its([:xyz])     { should == 1 }
  end

  context 'a command is created from a hash that has stringy keys which should match the attributes on the message' do
    let(:command)   { SomeExample.v(2).new 'xyz' => 1, 'abc' => 2 }

    subject { command.to_hash[:body] }

    its([:abc])     { should == 2 }
    its([:xyz])     { should == 1 }
  end

end
