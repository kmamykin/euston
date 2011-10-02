module Euston
  module Repository
    class << self
      attr_accessor :event_store

      # def find(type, id)  mixed in by event store implementation
      # def save(aggregate) mixed in by event store implementation
    end
  end
end
