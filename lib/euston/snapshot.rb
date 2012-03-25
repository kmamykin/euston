module Euston
  class Snapshot
    def initialize type, version, message_ids, payload
      @type, @version, @message_ids, @payload = type, version, message_ids, payload
    end

    attr_reader :type, :version, :message_ids, :payload
  end
end
