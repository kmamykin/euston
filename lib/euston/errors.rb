module Euston
  class InitializationRedefinitionError < StandardError; end
  class InvalidCommandError < StandardError; end
  class InvalidTransitionStateError < StandardError; end
  class SnapshotRedefinitionError < StandardError; end
  class SubscriptionRedefinitionError < StandardError; end
  class UnknownMessageError < StandardError; end
  class UnknownSnapshotError < StandardError; end
  class UnroutableMessageError < StandardError; end
  class UnverifiableMessageSource < StandardError; end
end
