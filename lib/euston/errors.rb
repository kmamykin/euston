module Euston
  module Errors
    class InvalidCommandError < StandardError; end
    class AggregateNotFoundError < StandardError; end
  end
end
