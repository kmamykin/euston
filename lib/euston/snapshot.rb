module Euston
  class Snapshot
    def initialize type, sequence, version, message_ids, payload
      @type, @sequence, @version, @message_ids, @payload = type, sequence, version, message_ids, payload
    end

    attr_reader :type, :sequence, :version, :message_ids, :payload
  end
end
