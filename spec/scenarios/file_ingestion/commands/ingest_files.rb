module Scenarios
module FileIngestion

class IngestFiles < Euston::Command
  version 1 do
    validates :batch_id,  presence: true
    validates :files,     presence: true
  end
end

end
end
