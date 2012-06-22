module Scenarios
module GolfCourse

class Secretary
  include Euston::MessageSource

  initialization do
    @players_with_warnings = {}
  end

  events

  group_playing_slowly :course_id do |headers, body|
    transition_to :warning_issued_for_slow_play, 1, body
  end

  transitions

  warning_issued_for_slow_play do |body|
    @players_with_warnings[body[:player_id]] = :slow_play
  end

  snapshots

  load_from 1 do |payload|
    @players_with_warnings = payload[:players_with_warnings]
  end

  save_to 1 do
    { players_with_warnings: @players_with_warnings }
  end
end

end
end
