module Euston
  class EventHeaders
    attr_reader :id, :type, :version, :timestamp, :command

    def initialize id, type, version, timestamp = Time.now, command = nil
      @id = id
      @type = type
      @version = version
      @timestamp = Time.at(timestamp).utc
      @command = command
    end

    def self.from_hash hash
      self.new hash[:id], hash[:type].to_sym, hash[:version], hash[:timestamp], hash[:command]
    end
  end
end
