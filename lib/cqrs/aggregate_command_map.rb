module Cqrs
  class AggregateCommandMap
    class << self      
      def deliver_command(headers, command)
        mapping = @map.find { |m| m[:created_by][:type] == headers.type }

        if mapping.nil?
          aggregate = @map.find { |m| m[:consumes].any? { |c| c[:type] == headers.type } }
          return if aggregate.nil?

          mapping = aggregate[:consumes].find { |k| k[:type] == headers.type }

          deliver_command_to_existing_aggregate aggregate, headers, command
        elsif load_aggregate_for_command(mapping, headers, command).nil?
          construct_new_aggregate mapping[:type], headers, command
        end
      end      

      def map_command_as_aggregate_constructor(type, command, identifier, to_i = [])
        @map ||= []
        aggregate = get_aggregate(type)

        if aggregate.nil?
          aggregate = { :type => type,
                        :created_by => { :type => command, 
                                         :identifier => identifier,
                                         :to_i => to_i },
                        :consumes => [] }

          @map << aggregate
        end
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

      def construct_new_aggregate(type, headers, command)
        aggregate = type.new
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
      
      def load_aggregate_for_command(mapping, headers, command)
        if mapping[:created_by][:type] == headers.type
          identifier = command[mapping[:created_by][:identifier]]
        else
          identifier = mapping[:consumes].find { |c| c[:type] == headers.type }[:identifier]
        end

        Repository.find(mapping[:type], command[identifier])
      end
    end
  end
end