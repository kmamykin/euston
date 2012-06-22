module Euston
  class EventSourceHistory
    def self.empty event_source_type
      EventSourceHistory.new id: Uuid.generate, type: event_source_type
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

      @type = opts[:type].to_s unless opts[:type].nil?
      @type = @snapshot.event_source_id.type unless @snapshot.nil?
      @type = @commits.last.event_source_id.type unless @commits.empty?

      raise 'You must pass a :type when creating an EventSourceHistory without any snapshots or commits' if @type.nil?

      @event_source_id = EventSourceId.new @id, @type
    end

    def next_sequence
      @sequence + 1
    end

    attr_reader :commits, :event_source_id, :sequence, :snapshot
  end
end
