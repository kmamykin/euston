module Euston

module EventHandler
  extend ActiveSupport::Concern
  include MessageHandler

  module ClassMethods
    def events
      @message_map_section = :events
    end
  end
end

end
