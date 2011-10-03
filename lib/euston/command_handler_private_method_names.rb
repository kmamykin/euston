module Euston
  module CommandHandlerPrivateMethodNames
    extend ActiveSupport::Concern

    module ClassMethods
      def command_handler_method_name version
        "__version__#{version}"
      end
    end
  end
end
