module Euston
  module Repository
    class << self
      attr_accessor :event_store

      def find type, id
        pair = event_store.get_snapshot_stream_pair id
        return nil if pair.snapshot.nil? && pair.stream.committed_events.empty?

        type.hydrate pair.stream, pair.snapshot
      end

      def save aggregate
        stream = event_store.open_stream :stream_id => aggregate.aggregate_id
        aggregate.uncommitted_events.each { |e| stream << e }
        stream.uncommitted_headers[:aggregate_type] = aggregate.class.to_s
        stream.commit_changes Euston.uuid.generate
      end
    end
  end
end
