module Euston

module CommandHandler
  extend ActiveSupport::Concern
  include MessageHandler

  module ClassMethods
    def commands
      @message_map_section = :commands
    end
  end
end

end
