module Scenarios
module GolfCourse

class ScoreLogged < Euston::Event
  version 1 do
    validates :course_id,   presence: true
    validates :player_id,   presence: true
    validates :score,       presence: true,   numericality: { only_integer: true, greater_than: 0 }
    validates :time,        presence: true,   numericality: { greater_than: 0 }
  end
end

end
end
