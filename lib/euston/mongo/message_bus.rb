module Euston
module Mongo

class MessageBus
  def initialize message_class_finder, global_message_handler_map, data_store, logger = Euston::NullLogger.instance
    @data_store = data_store
    @global_message_handler_map = global_message_handler_map
    @message_class_finder = message_class_finder
    @log = logger
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

  def build_message_source_handlers handler_type, message, mapping, message_source_ids
    message_source_ids.map do |message_source_id|
      if @data_store.already_processed_message? message_source_id, message[:headers][:id]
        nil
      else
        start_time = Time.now.to_f
        history = @data_store.get_history(message_source_id) || MessageSourceHistory.new(id: message_source_id.id, type: message_source_id.type)

        @log.debug "Rebuilding #{history.message_source_id.type} with id #{history.message_source_id.id} and sequence #{history.sequence} from: #{history.commits.count} commit(s), #{history.snapshot.nil? ? 0 : 1} snapshot(s)" if @log.debug?

        handler_type.new(@message_class_finder, history).when(:commit_created) do |commit|
          commit.duration = Time.now.to_f - start_time
          @data_store.put_commit commit
        end
      end
    end
  end

  def get_message_source_ids handler_type, message, mapping
    message_source_ids = []

    if mapping[:identifier] == :correlated
      (message[:headers][:correlations] || []).map do |identifier|
        message_source_id = MessageSourceId.new identifier, handler_type
        message_source_ids << message_source_id if @data_store.has_commits message_source_id
      end
    else
      identifier = message[:body][mapping[:identifier]] || handler_type.message_map.to_hash[:identifier] || Uuid.generate
      message_source_ids << MessageSourceId.new(identifier, handler_type)
    end

    message_source_ids
  end

  def invoke_handler handler_type, message
    mapping = handler_type.message_map.get_mapping_for_message message

    handlers = if handler_type.included_modules.include?(MessageSource)
      message_source_ids = get_message_source_ids handler_type, message, mapping
      build_message_source_handlers handler_type, message, mapping, message_source_ids
    else
      [ handler_type.new ]
    end

    handlers.compact.each do |handler|
      begin
        handler.log = @log
        handler.consume message
      rescue => e
        last_exception = e
      end
    end

    raise unless $!.nil?
  end
end

end
end
