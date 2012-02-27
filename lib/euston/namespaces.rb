module Euston
  class Namespaces
    def initialize event_sources = [], commands = [], events = []
      @commands       = [commands].flatten.compact
      @events         = [events].flatten.compact
      @event_sources  = [event_sources].flatten.compact
    end

    attr_reader :commands, :events, :event_sources
  end
end
