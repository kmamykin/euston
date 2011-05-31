module Cqrs
  module CommandBus
    def self.publish headers, command
      aggregate = AggregateCommandMap.deliver_command headers, command
      raise "No aggregate found to handle command: #{headers} #{command}" if aggregate.nil?

      Repository.save aggregate
    end
  end
end