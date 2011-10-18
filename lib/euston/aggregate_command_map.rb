module Euston
  class AggregateMap < Array
    def find_entry_by_type(type)
      find { |a| a[:type] == type }
    end

    def find_entry_with_mapping_match(spec)
      find { |m| m[:mappings].any_mapping_matching?(spec) }
    end
  end

  class AggregateEntry < Hash
    def find_identifier_by_type(type)
      mapping = self[:mappings].find_mapping_for_type(type)
      return mapping[:identifier] if mapping
      nil
    end
  end

  class MappingMap < Array
    def has_mapping?(value, key = :type)
      self.any? { |m| m[key] == value }
    end

    def find_mapping_for_type(type)
      find { |c| c[:type] == type }
    end

    def any_mapping_matching?(spec)
      any? { |c| (c.keys & spec.keys).all? {|k| c[k] == spec[k]} }
    end

    def find_mapping_matching(spec)
      find {|c| (c.keys & spec.keys).all? {|k| c[k] == spec[k]} }
    end

    def push_if_unique(mapping, type)
      return if has_mapping?(type)
      push(mapping)
    end
  end

  class AggregateCommandMap
    class << self
      attr_reader :map #for tests

      def map_command_as_aggregate_constructor(type, command, identifier, to_i = [])
        @map ||= AggregateMap.new
        mapping = { :kind => :construct, :type => command, :identifier => identifier, :to_i => to_i }
        if ( aggregate_entry = @map.find_entry_by_type(type) )
          aggregate_entry[:mappings].push_if_unique(mapping, command)
        else
          @map << AggregateEntry.new.merge!( :type => type, :mappings => MappingMap.new.push(mapping) )
        end
      end

      def map_command_as_aggregate_method(type, command, identifier, to_i = [])
        mapping = { :kind => :consume, :type => command, :identifier => identifier, :to_i => to_i }
        aggregate_entry =  @map.find_entry_by_type(type)
        aggregate_entry[:mappings].push_if_unique(mapping, command)
      end

      def deliver_command(headers, command, logger = Euston::NullLogger.instance)
        args = [headers, command]
        query = {:kind => :construct, :type => headers.type}
        if (entry = @map.find_entry_with_mapping_match( query ))
          aggregate = load_aggregate(entry, *args) || create_aggregate(entry, *args)
        else
          query[:kind] = :consume
          entry = @map.find_entry_with_mapping_match( query )
          return unless entry
          aggregate = load_aggregate(entry, *args)
        end

        raise Euston::Errors::AggregateNotFoundError if aggregate.nil?

        aggregate.log = logger
        aggregate.consume_command( headers, command )
      end

      private

      def create_aggregate(map_entry, headers, command)
        identifier = map_entry.find_identifier_by_type(headers.type)
        aggregate_id = command[identifier] || Euston.uuid.generate
        map_entry[:type].new(aggregate_id)
      end

      def load_aggregate(map_entry, headers, command)
        identifier = map_entry.find_identifier_by_type(headers.type)
        Repository.find(map_entry[:type], command[identifier])
      end
    end
  end
end
