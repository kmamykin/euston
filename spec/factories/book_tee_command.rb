class Cranky::Factory
  def book_tee_command
    Scenarios::GolfCourse::BookTee.v(1).new define(
      class: Hash,
      course_id: Uuid.generate,
      player_id: Uuid.generate,
      time: Time.now.to_f + rand(1000))
  end
end
