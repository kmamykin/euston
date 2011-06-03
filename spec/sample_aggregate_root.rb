module Cqrs
  module Sample
    class Widget
      include Cqrs::AggregateRoot

      created_by :import_widget do |command|
        apply_event :widget_imported, 1, command
      end

      consumes :log_access, :id => :widget_id do |command|
        apply_event :access_logged, 1, :widget_id => command.widget_id,
                                       :access_count => @access_count + 1
      end

      applies :widget_imported, 1 do |event|
        @access_count = 0
      end

      applies :access_logged, 1 do |event|
        @access_count = event.access_count
      end
    end
  end
end