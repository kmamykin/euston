require 'active_support/concern'
require 'active_model'
require 'ostruct'
require 'set'

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

require 'euston/errors'
require 'euston/aggregate_command_map'
require 'euston/aggregate_root_private_method_names'
require 'euston/aggregate_root_dsl_methods'
require 'euston/command'
require 'euston/command_bus'
require 'euston/command_handler_private_method_names'
require 'euston/command_handler'
require 'euston/command_headers'
require 'euston/event'
require 'euston/event_handler_private_method_names'
require 'euston/event_handler'
require 'euston/event_headers'
require 'euston/null_logger'
require 'euston/aggregate_root'
require 'euston/repository'
