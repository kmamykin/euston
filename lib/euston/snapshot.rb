module Euston
  class Snapshot
    def initialize options
      options = {
        body: {},
        version: 1
      }.merge options

      @event_source_id          = options[:event_source_id]
      @sequence                 = options[:sequence]
      @type                     = options[:type]
      @version                  = options[:version]
      @body                     = options[:body]
    end

    attr_reader :event_source_id, :sequence, :type, :version, :body
  end
end
