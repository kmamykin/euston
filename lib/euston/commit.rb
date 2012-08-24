module Euston
  class Commit
    def initialize options
      defaults = {
        id: Uuid.generate,
        sequence: 1,
        commands: [],
        events: [],
        timestamp: Time.now.utc,
        duration: nil
      }

      options = defaults.merge options

      @commands           = options[:commands]
      @duration           = options[:duration]
      @message_source_id  = options[:message_source_id]
      @events             = options[:events]
      @id                 = options[:id]
      @origin             = options[:origin]
      @sequence           = options[:sequence]
      @timestamp          = options[:timestamp]

      @origin[:headers].delete :origin unless @origin.nil?
    end

    def store_command command, opts = {}
      command = marshal_dup command.to_hash
      merge_correlations_header command, opts

      @commands << command
    end

    def store_event event, opts = {}
      event = marshal_dup event.to_hash
      merge_correlations_header event, opts
      event[:headers][:sequence] = @sequence + @events.length

      @events << event
    end

    attr_reader :commands, :message_source_id, :events, :id, :origin, :sequence, :timestamp
    attr_accessor :duration

    def empty?
      @commands.empty? && @events.empty?
    end

    private

    def merge_correlations_header message, opts
      headers = message[:headers]

      listeners = headers[:correlations] = []
      listeners.push *(@origin[:headers][:correlations] || [])
      listeners << @message_source_id.id if opts[:correlated] && !(listeners.include? @message_source_id.id)

      headers.delete :correlations if listeners.empty?
    end
  end
end
