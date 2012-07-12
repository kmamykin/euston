module Euston
  class MessageSourceId
    def initialize id, type
      @id, @type = id, type

      unless type.is_a? String
        @klass = type
        @type = type.to_s
      end
    end

    def inspect
      "#{@id} (#{@type})"
    end

    def klass
      if @klass.nil?
        ConstantLoader.new.when(
          hit:  ->(type) { @klass = type },
          miss: ->{ raise "Failed to locate namespace: #{@type}" }
        ).load @type
      end

      @klass
    end

    attr_reader :id, :type
  end
end
