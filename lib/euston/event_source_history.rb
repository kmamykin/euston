module Euston
  class EventSourceHistory
    def self.empty
      EventSourceHistory.new
    end

    def self.defaults
      @defaults ||= { commits: [], snapshot: nil }
    end

    def initialize opts = {}
      opts = self.class.defaults.merge(opts)
      raise 'You must pass an :id when creating an EventSourceHistory' if opts[:id].nil?
      @id, @commits, @snapshot = opts[:id], opts[:commits], opts[:snapshot]

      @sequence = if @snapshot.nil?
        0
      else
        @snapshot.sequence
      end

      unless @commits.empty?
        @sequence = if @commits.last.empty?
          @commits.last.sequence
        else
          @commits.last.events.last[:headers][:sequence]
        end
      end

      @type = @snapshot.type unless @snapshot.nil?
      @type = @commits.last.type unless @commits.empty?
    end

    def next_sequence
      @sequence + 1
    end

    attr_reader :commits, :id, :sequence, :snapshot, :type
  end
end
