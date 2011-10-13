module Euston
  module EventHandler
    extend ActiveSupport::Concern
    include Euston::EventHandlerPrivateMethodNames

    included do
      attr_accessor :log unless public_method_defined? :log=
    end

    module ClassMethods
      def subscribes type, version = 1, opts = nil, &consumer
        if self.include? Euston::AggregateRoot
          o = { :id => :id }.merge opts

          self.class.send :define_method, id_from_event_method_name(type, version) do |event|
            if o[:id].respond_to? :call
              o[:id].call event
            else
              event[o[:id]]
            end
          end
        end

        define_method event_handler_method_name(type, version) do |*args|
          instance_exec *args, &consumer
        end
      end
    end
  end
end
