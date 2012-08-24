module Scenarios
module FileIngestion

class BatchIngested < Euston::Event
  version 1 do
    validates :batch_id,   presence: true
  end
end

end
end
