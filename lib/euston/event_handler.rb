module Euston
  module EventHandler
    extend ActiveSupport::Concern

    module ClassMethods
      def subscribes type, version, opts = nil, &consumer
        if self.include? Euston::AggregateRoot
          opts = opts || { :id => :id }

          define_method "__id_from_event_#{type}__v#{version}__" do |event|
            if opts[:id].respond_to? :call
              opts[:id].call event
            else
              event[opts[:id]]
            end
          end
        end

        define_method "__event_handler__#{type}__#{version}" do |*args|
          instance_exec *args, &consumer
        end
      end
    end
  end
end
