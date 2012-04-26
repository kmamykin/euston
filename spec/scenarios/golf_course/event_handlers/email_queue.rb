module Scenarios
module GolfCourse

class EmailQueue
  include Euston::EventHandler

  events

  warning_issued_for_slow_play 1 do |headers, body|

    # what might be done here in a real system:
    #   - load player details based on body[:player_id]
    #   - format an email to the player
    #   - enqueue the email for a background email-sender process to dispatch

    @queue ||= []
    @queue << body[:player_id]
  end
end

end
end
