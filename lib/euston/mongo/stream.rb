module Euston
module Mongo

class Stream
  def initialize event_source_id, commit_sequence, snapshot_sequence
    @event_source_id, @commit_sequence, @snapshot_sequence = event_source_id, commit_sequence, snapshot_sequence
  end

  # The event source that this stream represents
  attr_reader :event_source_id

  # The sequence number of the most recent commit to this stream
  attr_reader :commit_sequence

  # The sequence number of the most recent snapshot taken from this stream
  attr_reader :snapshot_sequence
end

end
end
