module Euston
  module AggregateRootPrivateMethodNames
    extend ActiveSupport::Concern

    module ClassMethods
      def applies_method_name event, version
        "__apply__#{event}__v#{version}__"
      end

      def consumes_method_name command, version
        "__consume__#{command}__v#{version}__"
      end

      def consumes_regex
        /__consume__(\w+)__v(\d+)__/
      end

      def id_from_event_method_name type, version
        "__id_from_event_#{type}__v#{version}__"
      end

      def load_snapshot_method_name version
        "__load_snapshot__v#{version}__"
      end

      def take_snapshot_method_name version
        "__take_snapshot__v#{version}__"
      end

      def take_snapshot_regexp
        /__take_snapshot__v(\d+)__/
      end
    end
  end
end
