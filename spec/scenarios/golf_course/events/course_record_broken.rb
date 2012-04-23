module Scenarios
module GolfCourse

class CourseRecordBroken < Euston::Event
  version 1 do
    validates :course_id,   presence: true
    validates :player_id,   presence: true
    validates :score,       presence: true,   numericality: { only_integer: true, greater_than: 0 }
  end
end

end
end
