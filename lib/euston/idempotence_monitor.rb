module Euston
  class IdempotenceMonitor
    def initialize history
      @message_ids = Set.new
      @message_ids.merge history.snapshot.message_ids unless history.snapshot.nil?
      @message_ids.merge history.commits.map { |c| c.origin }.compact.map { |o| o[:headers][:id] }
    end

    def already_encountered? message
      @message_ids.include? message[:headers][:id]
    end

    def memorize message_id
      @message_ids << message_id
    end

    def message_ids
      @message_ids.to_a
    end
  end
end
