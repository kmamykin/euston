module Euston
  class InvalidCommandError < StandardError; end
  class InvalidTransitionStateError < StandardError; end
  class SnapshotRedefinitionError < StandardError; end
  class SubscriptionRedefinitionError < StandardError; end
  class UnknownMessageError < StandardError; end
  class UnknownSnapshotError < StandardError; end
  class UnroutableMessageError < StandardError; end
  class UnverifiableEventSource < StandardError; end
end
