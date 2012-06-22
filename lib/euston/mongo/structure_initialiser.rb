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
    ], unique: false, name: 'dispatched_commits'

    commits.ensure_index [
      ['_id.id', asc],
      ['_id.type', asc],
      ['_id.sequence', asc],
      ['body.events.headers.sequence', asc]
    ], unique: false, name: 'commits_by_event_sequence'

    commits.ensure_index [
      ['_id.id', asc],
      ['_id.type', asc],
      ['headers.origin.headers.id', asc]
    ], unique: true, name: 'commit_idempotence_by_origin'

    streams.ensure_index [
      ['unsnapshotted', asc]
    ], unique: false, name: 'unsnapshotted_streams'
  end
end

end
end
