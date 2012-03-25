module Euston
  class EventSourceHistory
    def self.empty
      @empty_history ||= EventSourceHistory.new
    end

    def initialize commits = [], snapshot = nil
      @commits, @snapshot = commits, snapshot
    end

    attr_reader :commits, :snapshot
  end
end
