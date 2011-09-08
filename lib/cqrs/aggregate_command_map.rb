module Cqrs

  class AggregateMap < Array
    def find_entry_by_type(type)
      find { |a| a[:type] == type }
    end

    def find_entry_having_created_by_type(type)
      find_entry_by_mapping_type(:created_by,type)
    end

    def find_entry_having_consumes_type(type)
      find_entry_by_mapping_type(:consumes,type)
    end

    private

    def find_entry_by_mapping_type(key, type)
      find { |m| m[key].has_mapping?(type) }
    end
  end

  class AggregateEntry < Hash
    def find_identifier_by_type(type)
      [:created_by, :consumes].each do |key|
        mapping = self[key].find_mapping_for_type(type)
        return mapping[:identifier] if mapping
      end
      #default
    end
  end

  class MappingMap < Array
    def has_mapping?(command, key = :type)
      self.any? { |m| m[key] == command }
    end
    def find_mapping_for_type(type)
      find { |c| c[:type] == type }
    end
  end

  class AggregateCommandMap
    class << self

      def map_command_as_aggregate_constructor(type, command, identifier, to_i = [])
        @map ||= AggregateMap.new
        mapping = { :type => command, :identifier => identifier, :to_i => to_i }

        aggregate_entry = @map.find_entry_by_type(type)
        if aggregate_entry
          mappings = aggregate_entry[:created_by]
          mappings << mapping unless mappings.has_mapping?(command)
        else
          entry = AggregateEntry.new
          @map << entry.merge!( :type => type,
                    :consumes => MappingMap.new,
                    :created_by => MappingMap.new.push(mapping) )
        end
      end

      def map_command_as_aggregate_method(type, command, identifier, to_i = [])
        aggregate_entry = @map.find_entry_by_type(type)
        mappings = aggregate_entry[:consumes]

        return if mappings.has_mapping?(command)

        mappings << { :type => command,
                      :identifier => identifier,
                      :to_i => to_i }
      end

      def deliver_command(headers, command)
        map_entry = @map.find_entry_having_created_by_type( headers.type )
        if map_entry
          aggregate = load_aggregate_for_command( map_entry, headers, command )
          if aggregate.nil?
            identifier = map_entry.find_identifier_by_type( headers.type )
            aggregate_id = command[identifier] || Cqrs.uuid.generate
            aggregate = construct_new_aggregate( map_entry[:type], headers, command, aggregate_id )
          end
          aggregate
        else
          map_entry = @map.find_entry_having_consumes_type( headers.type )
          return unless map_entry
          deliver_command_to_existing_aggregate( map_entry, headers, command )
        end
      end

      private

      def construct_new_aggregate(type, headers, command, aggregate_id)
        type.new(aggregate_id).tap { |a| a.consume_command headers, command }
      end

      def deliver_command_to_existing_aggregate(map_entry, headers, command)
        load_aggregate_for_command(map_entry, headers, command).tap do |a|
          a.consume_command headers, command
        end
      end

      def load_aggregate_for_command(map_entry, headers, command)
        identifier = map_entry.find_identifier_by_type(headers.type)
        Repository.find(map_entry[:type], command[identifier])
      end
    end
  end
end
