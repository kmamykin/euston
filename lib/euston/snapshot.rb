module Euston
  class Snapshot
    def initialize options
      options = {
        body: {},
        version: 1,
        timestamp: Time.now.utc
      }.merge options

      @event_source_id          = options[:event_source_id]
      @sequence                 = options[:sequence]
      @type                     = options[:type]
      @version                  = options[:version]
      @timestamp                = options[:timestamp]
      @body                     = options[:body]
    end

    attr_reader :event_source_id, :sequence, :type, :version, :timestamp, :body
    attr_accessor :duration
  end
end
