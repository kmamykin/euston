module Scenarios
module FileIngestion

class FileIngestionFailed < Euston::Event
  version 1 do
    validates :file_id,   presence: true
  end
end

end
end
