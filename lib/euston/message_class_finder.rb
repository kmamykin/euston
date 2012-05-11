module Euston
  class MessageClassFinder
    def self.get_class_name name, version
      "#{name.to_s.camelize}_v#{version}"
    end

    def initialize namespaces
      @namespaces = namespaces
    end

    def find_command name, version
      find_message_class @namespaces.commands, 'command', name, version
    end

    def find_event name, version
      find_message_class @namespaces.events, 'event', name, version
    end

    private

    def find_message_class namespaces, type, name, version
      class_name = self.class.get_class_name name, version
      namespace = namespaces.find { |namespace| namespace.const_defined? class_name }

      raise "Couldn't locate a class file defining version #{version} of the #{name} #{type}" if namespace.nil?

      namespace.const_get class_name
    end
  end
end
