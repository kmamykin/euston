module MongoSpecMixin
  extend ActiveSupport::Concern

  def self.test_database
    'euston-event-store-specs'
  end

  included do
    let(:mongo_connection)  { Mongo::Connection.from_uri 'mongodb://127.0.0.1:27017/?safe=true;fsync=true;w=1;' }
    let(:mongo_db)          { mongo_connection.db MongoSpecMixin.test_database }

    before :each do
      mongo_db.collections.select { |c| c.name !~ /system/ }.to_a.each { |c| mongo_db.drop_collection c.name }
    end

    let(:event_store) do
      Euston::Mongo::EventStore.build do |config|
        config.database = MongoSpecMixin.test_database
      end
    end

    after :each do
      mongo_connection.close
    end
  end
end
