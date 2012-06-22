module Euston
module Mongo

class Stream
  def initialize opts
    @message_source_id = opts[:message_source_id]
    @commit_sequence = opts[:commit_sequence]
    @snapshot_sequence = opts[:snapshot_sequence]
  end

  # The event source that this stream represents
  attr_reader :message_source_id

  # The sequence number of the most recent commit to this stream
  attr_reader :commit_sequence

  # The sequence number of the most recent snapshot taken from this stream
  attr_reader :snapshot_sequence
end

end
end
