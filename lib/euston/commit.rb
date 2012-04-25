module Euston
  class Commit
    def initialize options
      defaults = {
        id: Uuid.generate,
        sequence: 1,
        commands: [],
        events: [],
        timestamp: Time.now.utc
      }

      options = defaults.merge options

      @id               = options[:id]
      @event_source_id  = options[:event_source_id]
      @sequence         = options[:sequence]
      @type             = options[:type]
      @origin           = options[:origin]
      @commands         = options[:commands]
      @events           = options[:events]
      @timestamp        = options[:timestamp]
    end

    def store_command command
      @commands << marshal_dup(command.to_hash)
    end

    def store_event event
      @events << marshal_dup(event.to_hash).tap { |e| e[:headers][:sequence] = @sequence + @events.length }
    end

    attr_reader :commands, :event_source_id, :events, :id, :origin, :sequence, :timestamp, :type

    def empty?
      @commands.empty? && @events.empty?
    end
  end
end
