module Euston
module Mongo

class MessageBus
  def initialize message_class_finder, global_message_handler_map, event_store
    @event_store = event_store
    @global_message_handler_map = global_message_handler_map
    @message_class_finder = message_class_finder
  end

  def handle_message message, handler = nil
    handler_types = if handler.nil?
      @global_message_handler_map.find_message_handlers(message).map { |h| h[:handler] }
    else
      [ handler ]
    end

    handler_types.each { |handler_type| invoke_handler handler_type, message }
  end

  private

  def invoke_handler handler_type, message
    mapping = handler_type.message_map.get_mapping_for_message message

    if handler_type.included_modules.include? EventSource
      start_time = Time.now.to_f
      event_source_id = message[:body][mapping[:identifier]]
      history = @event_store.get_history(event_source_id) || EventSourceHistory.new(id: event_source_id)

      handler_type.new(@message_class_finder, history).when(:commit_created) do |commit|
        commit.duration = Time.now.to_f - start_time
        @event_store.put_commit commit
      end.consume message
    else
      handler_type.new.consume message
    end
  end
end

end
end
