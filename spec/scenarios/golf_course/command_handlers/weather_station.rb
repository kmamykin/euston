module Scenarios
module GolfCourse

class WeatherStation
  include Euston::CommandHandler

  commands

  log_temperature 1 do |headers, body|

    # what might be done here in a real system:
    #   - load up the temperatures document
    #   - upsert today's temperature

    @temperatures ||= []
    @temperatures << body[:temperature]
  end
end

end
end
