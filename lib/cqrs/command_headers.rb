module Cqrs
  class CommandHeaders
    attr_reader :id, :type, :version

    def initialize id, type, version
      @id = id
      @type = type
      @version = version
    end

    def to_hash
      {
        :id => id,
        :type => type,
        :version => version
      }
    end

    def self.from_hash hash
      self.new hash[:id], hash[:type].to_sym, hash[:version]
    end
  end
end