# module Euston

# if RUBY_PLATFORM.to_s == 'java'
#   require 'jmongo'
#   require 'java'
#   import java.lang.System

#   module Clock
#     def self.now_in_seconds
#       now = System.nanoTime / 1000000000.0

#       { as_float: now, as_rfc3339: Time.at(now).to_datetime.rfc3339(6) }

#       # Java::JavaUtil::UUID.randomUUID().toString()
#     end
#   end

# else
#   module Clock
#     def self.timestamp
#       now = Time.now

#       { as_float: now.to_f, as_rfc3339: now.to_datetime.rfc3339(6) }
#     end
#   end

#   # require 'uuid'
#   # Uuid = UUID.new

#   # require 'mongo'
# end

# end
