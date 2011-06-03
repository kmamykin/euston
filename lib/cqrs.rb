require 'active_support/concern'
require 'ostruct'
require 'uuid'

module Cqrs
  class << self
    attr_accessor :uuid
  end
end

Cqrs.uuid = UUID.new

require 'cqrs/aggregate_command_map'
require 'cqrs/aggregate_root'
require 'cqrs/command_bus'
require 'cqrs/command_handler'
require 'cqrs/command_headers'
require 'cqrs/event_handler'
require 'cqrs/event_headers'
require 'cqrs/repository'