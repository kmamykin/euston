module Euston
  class CommandHeaders
    attr_reader :id, :type, :version, :log_completion

    def initialize id, type, version, log_completion = false
      @id = id
      @type = type
      @version = version
      @log_completion = log_completion
    end

    def to_hash
      {
        :id => id,
        :type => type,
        :version => version,
        :log_completion => log_completion
      }
    end

    def self.from_hash hash
      self.new hash[:id], hash[:type].to_sym, hash[:version], ( hash[:log_completion] || false )
    end
  end
end
