module Euston
  class EventSourceHistory
    def self.empty
      @empty_history ||= EventSourceHistory.new
    end

    def self.defaults
      @defaults ||= { age: 0, commits: [], snapshot: nil }
    end

    def initialize opts = {}
      opts = self.class.defaults.merge opts
      @age, @commits, @snapshot = opts[:age], opts[:commits], opts[:snapshot]
    end

    attr_reader :age, :commits, :snapshot
  end
end
