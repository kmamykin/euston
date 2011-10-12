module Euston
  module CommandBus
    def self.publish headers, command, logger = Euston::NullLogger.instance
      aggregate = AggregateCommandMap.deliver_command headers, command, logger
      raise "No aggregate found to handle command: #{headers} #{command}" if aggregate.nil?

      Repository.save aggregate
    end
  end
end
