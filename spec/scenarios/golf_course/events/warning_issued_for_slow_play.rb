module Scenarios
module GolfCourse

class WarningIssuedForSlowPlay < Euston::Event
  version 1 do
    validates :player_id,   presence: true
  end
end

end
end
