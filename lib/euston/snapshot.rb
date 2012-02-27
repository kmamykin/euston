module Euston
  class Snapshot
    def initialize type, version, payload
      @type, @version, @payload = type, version, payload
    end

    attr_reader :type, :payload, :version
  end
end
