module Euston
  class EventStream
    def initialize source_message, events = []
      @source_message, @events = source_message, events
      @commands = []
    end

    def store_command hash
      @commands << hash
    end

    def store_event name, version, body
      headers = { id: Uuid.generate, type: name, version: version }
      @events << { headers: headers, body: marshal_dup(body) }
    end

    attr_reader :commands, :events, :source_message
  end
end
