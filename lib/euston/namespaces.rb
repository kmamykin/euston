module Euston
  class Namespaces
    def initialize opts = {}
      @commands         = [opts[:commands]].flatten.compact.uniq
      @events           = [opts[:events]].flatten.compact.uniq
      @message_handlers = [opts[:message_handlers]].flatten.compact.uniq
    end

    def commands
      dereference_string_pointers @commands
    end

    def events
      dereference_string_pointers @events
    end

    def message_handlers
      dereference_string_pointers @message_handlers
    end

    private

    def dereference_string_pointers collection
      string_pointers = collection.find_all { |namespace| namespace.is_a? String }.to_a

      string_pointers.each do |namespace|
        ConstantLoader.new.when(
          hit:  ->(ns) { collection.delete(namespace); collection << ns },
          miss: ->{ raise "Failed to locate namespace: #{namespace}" }
        ).load namespace
      end

      collection
    end
  end
end
