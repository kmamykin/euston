require File.expand_path("../spec_helper", __FILE__)

module Euston
  describe 'aggregate root' do
    context 'duplicate command consumption' do
      let(:aggregate) { Sample::Widget.new }
      let(:aggregate2) { Sample::Widget.new }
      let(:command) { { :headers => CommandHeaders.new(Euston.uuid.generate, :create_widget, 1),
                        :body => { :id => Euston.uuid.generate } } }

      it 'does not handle the same command twice' do
        aggregate.consume_command command[:headers], command[:body]
        aggregate.uncommitted_events.should have(1).item

        aggregate.uncommitted_events.each { |e| aggregate2.replay_event e.headers, e.body }

        aggregate2.consume_command command[:headers], command[:body]
        aggregate2.uncommitted_events.should have(0).items
      end
    end
  end
end
