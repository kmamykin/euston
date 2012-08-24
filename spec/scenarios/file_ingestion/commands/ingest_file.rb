module Scenarios
module FileIngestion

class IngestFile < Euston::Command
  version 1 do
    validates :file_id,   presence: true
  end
end

end
end
