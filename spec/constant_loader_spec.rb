module ConstantLoaderTesting
  module SubNamespace
    class Foobar
    end
  end
end

describe 'constant loader' do
  let(:loader) { Euston::ConstantLoader.new }
  let(:outcome) { { :hit => nil, :miss => nil} }

  before { loader.when(:hit => ->(constant) { outcome[:hit] = constant }, :miss => ->{ outcome[:miss] = true }) }

  subject do
    loader.load constant_string
    outcome
  end

  context 'with a valid constant string' do
    let(:constant_string) { 'ConstantLoaderTesting::SubNamespace::Foobar' }

    its([:hit]) { should == ConstantLoaderTesting::SubNamespace::Foobar }
  end

  context 'with a totally invalid constant string' do
    let(:constant_string) { 'Something::Entirely::Made::Up' }

    its([:miss]) { should == true }
  end

  context 'with a partially invalid constant string' do
    let(:constant_string) { 'ConstantLoaderTesting::Missing' }

    its([:miss]) { should == true }
  end
end
