module Euston
  module Errors
    class InvalidCommandError < StandardError; end
    class AggregateNotFoundError < StandardError; end
    class CommandHeadersArgumentError < StandardError; end
  end
end
