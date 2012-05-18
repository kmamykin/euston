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

    def log
      @euston_logger ||= Euston::NullLogger.instance
    end

    def log= logger
      @euston_logger = logger
    end

    private

    def call_state_change_function type, version, headers, body
      method_name = self.class.message_map.get_method_name_for_message(type, version).to_sym
      method_arity = method(method_name).arity

      args = if method_arity == 0
        []
      elsif method_arity == 1
        [marshal_dup(body)]
      else
        [marshal_dup(headers), marshal_dup(body)]
      end

      send method_name, *args
    end
  end

  module ClassMethods
    def message_map
      @message_map ||= begin
        map = MessageHandlerMessageMap.new self

        map.initializer_defined { |*args| define_dsl_method *args }
        map.message_defined     { |*args| define_dsl_method *args }
        map.snapshot_defined    { |*args| define_dsl_method *args }
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

    private

    def define_dsl_method name, block
      if block.nil?
        define_method name do
          # empty block
        end
      else
        define_method name, &block
      end
    end
  end
end

end
