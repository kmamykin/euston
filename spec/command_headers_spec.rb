require File.expand_path("../spec_helper", __FILE__)

module Euston
  describe 'command_headers' do
    let(:header) { CommandHeaders.new(parameters) }
    context 'a new command headers object' do
      it 'traps incorrect construction' do
        expect { CommandHeaders.new({}) }.to raise_error(Errors::CommandHeadersArgumentError)
        expect { CommandHeaders.new(id: 'foo', type: 'bah') }.to raise_error(Errors::CommandHeadersArgumentError,/version/)
        expect { CommandHeaders.new(type: 'bah', version: 3) }.to raise_error(Errors::CommandHeadersArgumentError,/id/)
        expect { CommandHeaders.new(id: 'foo', version: 2) }.to raise_error(Errors::CommandHeadersArgumentError,/type/)
      end
      let(:parameters) {{ id: 'foo', type: 'bah', version: 3 }}
      it 'creates one from a hash' do
        CommandHeaders.from_hash(parameters).should == header
      end
    end
    context 'accessors' do
      let(:parameters) {{ id: 'foo', type: 'bah', version: 3 }}
      it 'converts type to a symbol' do
        header.type.should == :bah
      end
      it 'has various accessor methods' do
        header.id.should == 'foo'
        header.version.should == 3
        header[:id].should == 'foo'
        header[:type].should == :bah
        header['version'].should == 3
      end
      it 'treats respond_to correctly' do
        header.respond_to?(:type).should be_true
        header.respond_to?(:user_id).should be_false
      end
    end
    context 'with more than the basic attributes' do
      let(:parameters) {{ id: 'foo', type: 'bah', version: 3, user_id: 'bobby123' }}
      it 'allows access to the extra attributes' do
        header.respond_to?(:user_id).should be_true
        header.user_id.should == 'bobby123'
        header[:user_id].should == 'bobby123'
      end
    end
    context 'auxilliary methods' do
      let(:parameters) {{ id: 'foo', type: 'bah', version: 3, user_id: 'bobby123' }}
      it 'has methods' do
        header.to_hash.should == {id: 'foo', type: :bah, version: 3, user_id: 'bobby123'}
        header.to_s.should == 'foo bah (v3)'
      end
    end
  end
end
