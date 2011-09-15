module Euston
  module Sample
    class Widget
      include Euston::AggregateRoot

      created_by :create_widget do |command|
        apply_event :widget_created, 1, command
      end

      created_by :import_widget do |command|
        apply_event :widget_imported, 1, :access_count => (@access_count || 0) + command.imported_count
      end

      consumes :log_access_to_widget, :id => :widget_id do |command|
        apply_event :widget_access_logged, 1, :widget_id => command.widget_id,
                                       :access_count => @access_count + 1
      end

      applies :widget_created, 1 do |event|
        @access_count = 0
      end

      applies :widget_imported, 1 do |event|
        @access_count = event.access_count
      end

      applies :widget_access_logged, 1 do |event|
        @access_count = event.access_count
      end
    end

    class Product
      include Euston::AggregateRoot

      created_by :create_product do |command|
        apply_event :product_created, 1, command
      end

      created_by :import_product do |command|
        apply_event :product_imported, 1, :access_count => command.imported_count
      end

      consumes :log_access_to_product, :id => :product_id do |command|
        apply_event :product_access_logged, 1, :product_id => command.product_id,
                                       :access_count => @access_count + 1
      end
      applies :product_created, 1 do |event|
        @access_count = 0
      end

      applies :product_imported, 1 do |event|
        @access_count = event.access_count
      end

      applies :product_access_logged, 1 do |event|
        @access_count = event.access_count
      end
    end
  end
end
