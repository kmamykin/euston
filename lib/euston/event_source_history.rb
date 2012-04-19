module Euston
  class EventSourceHistory
    def self.empty
      @empty_history ||= EventSourceHistory.new
    end

    def self.defaults
      @defaults ||= { sequence: 1, commits: [], snapshot: nil }
    end

    def initialize opts = {}
      opts = self.class.defaults.merge opts
      @commits, @sequence, @snapshot = opts[:commits], opts[:sequence], opts[:snapshot]
    end

    def next_sequence
      return 1 if @sequence == 1 && @commits.empty? && @snapshot.nil?
      @sequence + @commits.length
    end

    attr_reader :commits, :sequence, :snapshot
  end
end
