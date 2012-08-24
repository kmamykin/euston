module Scenarios
module FileIngestion

class Single
  include Euston::MessageSource

  def self.fail_next_ingestion?
    !!@fail_next_ingestion
  end

  def self.fail_next_ingestion= fail
    @fail_next_ingestion = fail
  end

  commands

  ingest_file :file_id do |body|
    if Single.fail_next_ingestion?
      transition_to :file_ingestion_failed, 1, body
    else
      transition_to :file_ingested, 1, body
    end
  end

  transitions

  file_ingested
  file_ingestion_failed
end

end
end
