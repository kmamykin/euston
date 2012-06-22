module Euston
  class Snapshot
    def initialize options
      options = {
        body: {},
        version: 1,
        timestamp: Time.now.utc
      }.merge options

      @message_source_id          = options[:message_source_id]
      @sequence                 = options[:sequence]
      @version                  = options[:version]
      @timestamp                = options[:timestamp]
      @body                     = options[:body]
    end

    attr_reader :message_source_id, :sequence, :version, :timestamp, :body
    attr_accessor :duration
  end
end
