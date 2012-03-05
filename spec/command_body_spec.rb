require File.expand_path("../spec_helper", __FILE__)

module Euston
  describe 'command body' do
    class TestCommand < Euston::Command
      validates :a, presence: true
      validates :b, presence: true
    end

    let(:attributes)  { { a: :a, b: :b, c: :c } }
    let(:command)     { TestCommand.new attributes }

    subject { command.to_hash[:body] }

    it { should_not have_key :c }
  end
end
