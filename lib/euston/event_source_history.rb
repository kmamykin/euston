module Euston
  class EventSourceHistory
    def self.empty
      EventSourceHistory.new
    end

    def self.defaults
      @defaults ||= { sequence: 1, commits: [], snapshot: nil }
    end

    def initialize opts = {}
      opts = self.class.defaults.merge(id: Uuid.generate).merge(opts)
      @id, @commits, @sequence, @snapshot = opts[:id], opts[:commits], opts[:sequence], opts[:snapshot]
    end

    def next_sequence
      return 1 if @sequence == 1 && @commits.empty? && @snapshot.nil?
      @sequence + @commits.length
    end

    attr_reader :commits, :id, :sequence, :snapshot
  end
end
