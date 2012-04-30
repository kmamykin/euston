module Euston
module Mongo

class StructureInitialiser
  def initialize database
    @database = database
  end

  def prepare
    ErrorHandler.wrap do
      ensure_collections_exist
      ensure_indexes_exist
    end
  end

  private

  def ensure_collections_exist
    ['commits', 'snapshots', 'streams'].each do |name|
      @database.create_collection name unless @database.collection_names.include? name
    end
  end

  def ensure_indexes_exist
    commits = @database.collection 'commits'
    streams = @database.collection 'streams'

    asc = ::Mongo::ASCENDING

    commits.ensure_index [
      ['headers.dispatched', asc],
      ['headers.dispatcher_id', asc],
      ['headers.timestamp.as_float', asc]
    ], unique: false, name: 'dispatched_index'

    commits.ensure_index [
      ['_id.event_source_id', asc],
      ['body.events.headers.sequence', asc]
    ], unique: true, name: 'get_from_index'

    streams.ensure_index [
      ['unsnapshotted', asc]
    ], unique: false, name: 'unsnapshotted_index'
  end
end

end
end
