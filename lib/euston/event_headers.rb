module Euston
  class EventHeaders
    attr_reader :id, :type, :version, :timestamp, :source_message, :source_message_type

    def initialize id, type, version, timestamp = Time.now, source_message = nil, source_message_type = nil
      @id = id
      @type = type
      @version = version
      @timestamp = Time.at(timestamp).utc
      @source_message = source_message
      @source_message_type = source_message_type
    end

    def to_hash
      Hash[@source_message_type, @source_message].merge :id => id,
                                                        :type => type,
                                                        :version => version,
                                                        :timestamp => timestamp
    end

    def self.from_hash hash
      if hash.has_key? :command
        source_message = hash[:command]
        source_message_type = :command
      elsif hash.has_key? :event_subscription
        source_message = hash[:event_subscription]
        source_message_type = :event_subscription
      end

      self.new hash[:id], hash[:type].to_sym, hash[:version], hash[:timestamp], source_message, source_message_type
    end

    def to_s
      "#{id} #{type} (v#{version})"
    end
  end
end
