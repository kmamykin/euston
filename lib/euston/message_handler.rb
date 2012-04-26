module Euston

module MessageHandler
  extend ActiveSupport::Concern

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
