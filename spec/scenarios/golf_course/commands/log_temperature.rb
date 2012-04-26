module Scenarios
module GolfCourse

class LogTemperature < Euston::Command
  version 1 do
    validates :temperature, presence: true, numericality: { greater_than: 0 }
  end
end

end
end
