require 'active_support/concern'
require 'active_support/inflector'
require 'active_model'

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

def marshal_dup object
  Marshal.load(Marshal.dump object)
end

require 'euston/errors'
require 'euston/namespaces'
require 'euston/message'
require 'euston/message_class_finder'
require 'euston/event_source_history'
require 'euston/event_source_message_map'
require 'euston/event_source'
require 'euston/event_stream'
require 'euston/global_message_map'
require 'euston/snapshot'
