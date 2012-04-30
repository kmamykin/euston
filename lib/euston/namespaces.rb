module Euston
  class Namespaces
    def initialize opts = {}
      @commands         = [opts[:commands]].flatten.compact.uniq
      @events           = [opts[:events]].flatten.compact.uniq
      @message_handlers = [opts[:message_handlers]].flatten.compact.uniq
    end

    attr_reader :commands, :events, :message_handlers
  end
end
