module Euston
  class EventSourceHistory
    def self.empty
      @empty_history ||= EventSourceHistory.new
    end

    def initialize event_streams = [], snapshot = nil
      @event_streams, @snapshot = event_streams, snapshot
    end

    attr_reader :event_streams, :snapshot
  end
end
