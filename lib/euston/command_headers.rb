module Euston
  class CommandHeaders
    attr_reader :id, :type, :version, :user_id

    def initialize id, type, version, user_id = nil
      @id = id
      @type = type
      @version = version
      @user_id = user_id
    end

    def to_hash
      Hash[:id, @id, :type, @type, :version, @version, :user_id, @user_id]
    end

    def self.from_hash hash
      self.new hash[:id], hash[:type].to_sym, hash[:version], hash[:user_id]
    end

    def to_s
      "#{id} #{type} (v#{version})"
    end
  end
end
