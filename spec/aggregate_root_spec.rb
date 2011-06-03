describe 'aggregate root' do
  context 'duplicate command consumption' do
    let(:aggregate) { Cqrs::Sample::Widget.new }
    let(:aggregate2) { Cqrs::Sample::Widget.new }
    let(:command) { { :headers => Cqrs::CommandHeaders.new(Cqrs.uuid.generate, :import_widget, 1),
                      :body => { :id => Cqrs.uuid.generate } } }

    it 'does not handle the same command twice' do
      aggregate.consume_command command[:headers], command[:body]
      aggregate.uncommitted_events.should have(1).item

      aggregate.uncommitted_events.each { |e| aggregate2.replay_event e.headers, e.body }
      
      aggregate2.consume_command command[:headers], command[:body]      
      aggregate2.uncommitted_events.should have(0).items
    end
  end
end
