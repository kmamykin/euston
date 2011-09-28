require 'active_support/concern'
require 'active_model'
require 'require_all'
require 'ostruct'

module Euston
  class << self
    attr_accessor :uuid, :logger
  end
end

if RUBY_PLATFORM.to_s == 'java'
  module Uuid
    def self.generate
      Java::JavaUtil::UUID.randomUUID().toString()
    end
  end
else
  require 'uuid'
  Uuid = UUID.new
end

Euston.uuid = Uuid

require 'euston-eventstore'
require_rel 'euston'
