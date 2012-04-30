module MongoSpecMixin
  extend ActiveSupport::Concern

  def self.test_database
    'euston-event-store-specs'
  end

  included do
    before :each do
      connection = Mongo::Connection.from_uri 'mongodb://0.0.0.0:27017/?safe=true;fsync=true;w=1;'
      db = connection.db MongoSpecMixin.test_database
      db.collections.select { |c| c.name !~ /system/ }.each { |c| db.drop_collection c.name }
    end

    let(:event_store) do
      begin
        Euston::Mongo::EventStore.build do |config|
          config.database = MongoSpecMixin.test_database
        end
      rescue => e
      end
    end
  end
end
