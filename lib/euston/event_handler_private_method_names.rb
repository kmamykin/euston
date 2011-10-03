module Euston
  module EventHandlerPrivateMethodNames
    extend ActiveSupport::Concern

    module ClassMethods
      def id_from_event_method_name type, version
        "__id_from_event_#{type}__v#{version}__"
      end

      def event_handler_method_name type, version
        "__event_handler__#{type}__#{version}"
      end
    end
  end
end
