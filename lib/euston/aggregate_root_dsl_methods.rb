module Euston
  module AggregateRootDslMethods
    def applies event, version = 1, &block
      define_private_method applies_method_name(event, version), &block
    end

    def consumes *arguments, &block #*args is an array of symbols plus an optional options hash at the end
      commands, options = [], {}

      while (arg = arguments.shift) do
        commands << { :name => arg, :version => 1 } if arg.is_a?(Symbol)
        commands.last[:version] = arg if arg.is_a?(Integer)
        options = arg if arg.is_a?(Hash)
      end

      commands.each do |command|
        define_private_method consumes_method_name(command[:name], command[:version]), &block
        map_command :map_command_as_aggregate_method, self, command[:name], options
      end
    end

    def created_by command, version = 1, options = {}, &block
      define_method consumes_method_name(command, version), &block

      map_command :map_command_as_aggregate_constructor, self, command, options
    end

    def load_snapshot version, &block
      define_private_method load_snapshot_method_name(version), &block
    end

    def take_snapshot version, &block
      define_private_method take_snapshot_method_name(version), &block
    end

    private

    def define_private_method name, &block
      define_method name do |*args| instance_exec *args, &block end
    end

    def map_command(entry_point, type, command, opts)
      id = opts.has_key?(:id) ? opts[:id] : :id
      to_i = opts.key?(:to_i) ? opts[:to_i] : []

      Euston::AggregateCommandMap.send entry_point, type, command, id, to_i
    end
  end
end
