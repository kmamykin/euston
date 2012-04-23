# describe 'event store' do
#   let(:event_store) { Euston::EventStore.new }

#   context 'when the user attempts to load a non-existing event source' do
#     let(:event_source_id) { Uuid.generate }

#     subject { event_store.get event_source_id }

#     it { should be_nil }
#   end

#   context 'when the user saves a new event source' do
#     module ESSNES
#       class EventSourceExample
#         include Euston::EventSource

#         commands

#         walk_dog :dog_id do |headers, body|
#           transition_to :dog_walked, 1, body
#         end

#         transitions

#         dog_walked do |body|
#           @distance = body[:distance]
#         end
#       end

#       class WalkDog < Euston::Command
#         version 1 do
#           validates :dog_id,    presence: true
#           validates :distance,  presence: true
#         end
#       end

#       class DogWalked < Euston::Event
#         version 1 do
#           validates :dog_id,    presence: true
#           validates :distance,  presence: true
#         end
#       end
#     end

#     let(:command)               { ESSNES::WalkDog.v(1).new(dog_id: event_source_id, distance: distance).to_hash }
#     let(:distance)              { (1..100).to_a.sample }
#     let(:event_source_id)       { Uuid.generate }
#     let(:event_source)          { ESSNES::EventSourceExample.new }
#     let(:message_class_finder)  { Euston::MessageClassFinder.new Euston::Namespaces.new(ESSNES, ESSNES, ESSNES) }

#     subject { event_store.put event_source }
#   end
# end
