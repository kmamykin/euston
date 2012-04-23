module Scenarios
module GolfCourse

class Scorer
  include Euston::EventSource

  initialization do
    @rounds = []
    @course_records = {}
  end

  commands

  log_score :course_id do |headers, body|
    course_record = @course_records[body[:course_id]]
    transition_to :score_logged, 1, body
    transition_to :course_record_broken, 1, body if course_record.nil? || body[:score] < course_record
  end

  transitions

  course_record_broken do |body|
    @course_records[body[:course_id]] = body[:score]
  end

  score_logged do |body|
    @rounds << body.tap { |b| [:course_id, :time].each { |k| b.delete k } }
  end
end

end
end
