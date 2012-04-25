if RUBY_PLATFORM.to_s == 'java'
  module Uuid
    def self.generate
      Java::JavaUtil::UUID.randomUUID().toString()
    end
  end

  require 'jmongo'
else
  require 'uuid'
  Uuid = UUID.new

  require 'mongo'
end
