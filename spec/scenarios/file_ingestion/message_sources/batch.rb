module Scenarios
module FileIngestion

class Batch
  include Euston::MessageSource

  initialization do
    @files = {}
  end

  attr_reader :outcome, :files

  commands

  ingest_files :batch_id do |headers, body|
    body[:files].each_with_index do |file_id, index|
      publish_command IngestFile.v(1).new(file_id: file_id), correlated: true
      transition_to :batch_ingesting_file, 1, batch_id: message_source_id, file_id: file_id
    end
  end

  events

  file_ingested :correlated do |headers, body|
    transition_to :file_ingested_in_batch, 1, body.merge(batch_id: message_source_id)
    check_if_batch_has_finished
  end

  file_ingestion_failed :correlated do |headers, body|
    transition_to :file_ingestion_in_batch_failed, 1, body.merge(batch_id: message_source_id)
    check_if_batch_has_finished
  end

  transitions

  batch_ingested do |body|
    @outcome = :succeeded
  end

  batch_ingestion_failed do |body|
    @outcome = :failed
  end

  batch_ingesting_file do |body|
    @files[body[:file_id]] = :ingesting
  end

  file_ingested_in_batch do |body|
    @files[body[:file_id]] = :ingested
  end

  file_ingestion_in_batch_failed do |body|
    @files[body[:file_id]] = :failed
  end

  private

  def check_if_batch_has_finished
    return if @files.any? { |file_id, status| status == :ingesting }

    if @files.any? { |file_id, status| status == :failed }
      transition_to :batch_ingestion_failed, 1, batch_id: message_source_id
    else
      transition_to :batch_ingested, 1, batch_id: message_source_id
    end
  end
end

end
end
