class Cranky::Factory
  def check_for_slow_play_command
    Scenarios::GolfCourse::CheckForSlowPlay.v(1).new define(
      class: Hash,
      course_id: Uuid.generate,
      player_id: Uuid.generate,
      time: Time.now.to_f + rand(1000))
  end
end
