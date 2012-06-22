module Scenarios
module GolfCourse

class Starter
  include Euston::MessageSource

  initialization do
    @bookings = {}
  end

  commands

  book_tee :course_id do |headers, body|
    if @bookings[body[:time]].nil?
      transition_to :tee_booked, 1, body
    else
      transition_to :tee_booking_rejected, 1, body
    end
  end

  cancel_tee_booking :course_id do |headers, body|
    booking = @bookings[body[:time]]

    transition_to :tee_booking_cancelled, 1, body unless booking.nil? || booking != body[:player_id]
  end

  check_for_slow_play :course_id do |headers, body|
    unless @bookings[body[:time]][:finished]
      transition_to :group_playing_slowly, 1, body
    end
  end

  start_group :course_id do |headers, body|
    transition_to :round_started, 1, body
    publish_command CheckForSlowPlay.v(1).new({ send_at: Time.now + 60*60*4 }, body)
  end

  events

  score_logged :course_id do |headers, body|
    transition_to :round_completed, 1, body
  end

  transitions

  round_completed do |body|
    @bookings[body[:time]][:finished] = true
  end

  round_started do |body|
    @bookings[body[:time]][:finished] = false
  end

  tee_booked do |body|
    @bookings[body[:time]] = { player_id: body[:player_id] }
  end

  tee_booking_cancelled do |body|
    @bookings.delete body[:time]
  end

  tee_booking_rejected do; end
end

end
end
