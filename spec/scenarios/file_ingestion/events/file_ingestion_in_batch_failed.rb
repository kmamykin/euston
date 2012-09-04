module Scenarios
module FileIngestion

class FileIngestionInBatchFailed < Euston::Event
  version 1 do
    validates :batch_id,  presence: true
    validates :file_id,   presence: true
  end
end

end
end