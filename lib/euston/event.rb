module Euston
  class Event
    def initialize data = {}
      if (data.keys & ['body', 'headers']).size == 2
        @body, @headers = data.values_at 'body', 'headers'
      else
        @headers = {}
        @body = data
      end
    end

    attr_reader :headers, :body

    def to_hash
      { :headers => @headers, :body => @body }
    end
  end
end
