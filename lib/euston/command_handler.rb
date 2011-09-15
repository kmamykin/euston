module Euston
  module CommandHandler
    extend ActiveSupport::Concern

    module ClassMethods
      def version number, &consumer
        define_method "__version__#{number}" do |*args|
          if block_given?
            instance_exec *args, &consumer
          else
            publish args.shift, args.shift
          end
        end
      end
    end

    module InstanceMethods
      protected

      def publish headers, command
        Euston::CommandBus.publish headers, command
      end
    end
  end
end