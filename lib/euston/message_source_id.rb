module Euston
  class MessageSourceId
    def initialize id, type
      @id, @type = id, type.to_s
    end

    def inspect
      "#{@id} (#{@type})"
    end

    attr_reader :id, :type
  end
end
