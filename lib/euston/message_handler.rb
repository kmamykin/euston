module Euston

module MessageHandler
  extend ActiveSupport::Concern

  included do
    def consume message
      call_state_change_function message[:headers][:type],
                                 message[:headers][:version],
                                 message[:headers],
                                 message[:body]
    end

    private

    def call_state_change_function type, version, headers, body
      method_name = self.class.message_map.get_method_name_for_message(type, version).to_sym

      args = [marshal_dup(body)]
      args.unshift marshal_dup(headers) if method(method_name).arity > 1

      send method_name, *args
    end
  end

  module ClassMethods
    def message_map
      @message_map ||= begin
        map = MessageHandlerMessageMap.new self
        map.initializer_defined { |name, block| define_method name, &block }
        map.message_defined     { |name, block| define_method name, &block }
        map.snapshot_defined    { |name, block| define_method name, &block }
        map
      end
    end

    def method_missing method, *args, &block
      if @message_map_section.nil?
        super.method_missing method, *args, &block
      elsif @message_map_section == :snapshots
        if message_map.snapshot_method? method
          message_map.define_snapshot method, args, &block
        else
          super.method_missing method, *args, &block
        end
      else
        message_map.define @message_map_section, method, args, &block
      end
    end
  end
end

end
