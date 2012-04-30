module Euston
  class Snapshot
    def initialize options
      options = {
        body: {},
        idempotence_message_ids: [],
        version: 1
      }.merge options

      @event_source_id          = options[:event_source_id]
      @sequence                 = options[:sequence]
      @type                     = options[:type]
      @version                  = options[:version]
      @idempotence_message_ids  = options[:idempotence_message_ids]
      @body                     = options[:body]
    end

    attr_reader :event_source_id, :sequence, :type, :version, :idempotence_message_ids, :body
  end
end
