module Scenarios
module FileIngestion

class FileIngested < Euston::Event
  version 1 do
    validates :file_id,   presence: true
  end
end

end
end
