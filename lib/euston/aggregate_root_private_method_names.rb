module Euston
  module AggregateRootPrivateMethodNames
    def applies_method_name event, version
      "__apply__#{event}__v#{version}__"
    end

    def consumes_method_name command, version
      "__consume__#{command}__v#{version}__"
    end

    def load_snapshot_method_name version
      "__load_snapshot__v#{version}__"
    end

    def take_snapshot_method_name version
      "__take_snapshot__v#{version}__"
    end
  end
end
