module Euston
  class Commit
    def initialize origin, events = []
      @origin, @events = origin, events
      @commands = []
    end

    def store_command hash
      @commands << hash
    end

    def store_event name, version, body
      headers = { id: Uuid.generate, type: name, version: version }
      @events << { headers: headers, body: marshal_dup(body) }
    end

    attr_reader :commands, :events, :origin

    def empty?
      @commands.empty? && @events.empty?
    end
  end
end
