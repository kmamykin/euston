module Scenarios
module GolfCourse

class CancelTeeBooking < Euston::Command
  version 1 do
    validates :course_id,   presence: true
    validates :player_id,   presence: true
    validates :time,        presence: true,   numericality: { greater_than: 0 }
  end
end

end
end
