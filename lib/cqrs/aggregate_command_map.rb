module Cqrs
  class AggregateCommandMap
    class << self
      def deliver_command(headers, command)
        mapping = @map.find { |m| m[:created_by][:type] == headers.type }
        if mapping.nil?
          mapping = @map.find { |m| m[:consumes].any? { |c| c[:type] == headers.type } }
          return if mapping.nil?
          deliver_command_to_existing_aggregate mapping, headers, command
        else
          aggregate = load_aggregate_for_command(mapping, headers, command)
          if aggregate.nil?
            identifier = find_identifier(mapping, headers)
            aggregate_id = command[identifier] || Cqrs.uuid.generate
            aggregate = construct_new_aggregate(mapping[:type], headers, command, aggregate_id)
          end
          aggregate
        end
      end

      def map_command_as_aggregate_constructor(type, command, identifier, to_i = [])

        @map ||= []

        return if get_aggregate(type)

        @map << { :type => type,
                  :consumes => [],
                  :created_by => { :type => command,
                                   :identifier => identifier,
                                   :to_i => to_i
                                 }
                }
      end

      def map_command_as_aggregate_method(type, command, identifier, to_i = [])
        aggregate = get_aggregate type
        mappings = aggregate[:consumes]

        unless mappings.any? { |m| m[:type] == command }
          mappings << { :type => command,
                        :identifier => identifier,
                        :to_i => to_i }
        end
      end

      private

      def construct_new_aggregate(type, headers, command, aggregate_id)
        aggregate = type.new aggregate_id
        aggregate.consume_command headers, command
        aggregate
      end

      def deliver_command_to_existing_aggregate(mapping, headers, command)
        aggregate = load_aggregate_for_command mapping, headers, command
        aggregate.consume_command headers, command
        aggregate
      end

      def get_aggregate(type)
        aggregate = @map.find { |a| a[:type] == type }
        aggregate
      end

      def find_identifier(mapping, headers)
        if mapping[:created_by][:type] == headers.type
          mapping[:created_by][:identifier]
        else
          mapping[:consumes].find { |c| c[:type] == headers.type }[:identifier]
        end
      end

      def load_aggregate_for_command(mapping, headers, command)
        identifier = find_identifier(mapping, headers)
        Repository.find(mapping[:type], command[identifier])
      end
    end
  end
end