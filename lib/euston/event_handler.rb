module Euston
  module EventHandler
    extend ActiveSupport::Concern
    include Euston::EventHandlerPrivateMethodNames

    included do
      attr_accessor :log unless public_method_defined? :log=
    end

    module ClassMethods
      def subscribes type, version = 1, opts = {}, &consumer
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

        method_name = event_handler_method_name type, version
        define_method method_name, &consumer
        new_method = instance_method method_name

        define_method method_name do |*args|
          new_method.bind(self).call *args
        end
      end
    end
  end
end
