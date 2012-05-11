module Euston
module Mongo

class EventStore
  def self.build &block
    config = Config.new

    yield config

    options = {}
    options.merge!(:logger => config.logger) unless config.logger.nil?

    connection = ::Mongo::Connection.from_uri config.uri, options
    EventStore.new connection.db config.database
  end

  def initialize database
    Euston::Mongo::StructureInitialiser.new(database).prepare

    @commits    = database.collection 'commits'
    @snapshots  = database.collection 'snapshots'
    @streams    = database.collection 'streams'

    @ascending  = ::Mongo::ASCENDING
    @descending = ::Mongo::DESCENDING
  end

  def find_commits options = {}
    ErrorHandler.wrap do
      if options.keys.empty?
        query = {}
        order = [ 'headers.timestamp.as_float', @ascending ]
      else
        options = { min_sequence: 0, max_sequence: FIXNUM_MAX }.merge options

        query = {
          '_id.event_source_id' => options[:event_source_id],
          'body.events.headers.sequence' => {
            '$gte' => options[:min_sequence],
            '$lte' => options[:max_sequence] } }

        order = [ 'body.events.headers.sequence', @ascending ]
      end

      map_over @commits.find(query, sort: order).to_a, :get_commit_from_document
    end
  end

  def find_streams_to_snapshot max_threshold
    ErrorHandler.wrap do
      query = { 'unsnapshotted' => { '$gte' => max_threshold } }
      order = [ 'unsnapshotted', @descending ]

      map_over @streams.find(query, sort: order).to_a, :get_stream_from_document
    end
  end

  def find_dispatchable_commits dispatcher_id
    ErrorHandler.wrap do
      query = {
        'headers.dispatched' => false,
        'headers.dispatcher_id' => dispatcher_id
      }

      order = [ 'headers.timestamp.as_float', @ascending ]

      map_over @commits.find(query, sort: order, batch_size: 100).to_a, :get_commit_from_document
    end
  end

  def get_history event_source_id
    snapshot = get_snapshot event_source_id

    commit_criteria = { event_source_id: event_source_id }
    commit_criteria[:min_sequence] = snapshot.sequence + 1 unless snapshot.nil?
    commits = find_commits commit_criteria

    return nil if snapshot.nil? && commits.empty?

    EventSourceHistory.new id: event_source_id, commits: commits, snapshot: snapshot
  end

  def get_snapshot event_source_id, max_sequence = FIXNUM_MAX
    ErrorHandler.wrap do
      query = { '_id' => {  '$gt' => { 'event_source_id' => event_source_id, 'sequence' => nil },
                           '$lte' => { 'event_source_id' => event_source_id, 'sequence' => max_sequence } } }

      order = [ '_id', @descending ]

      map_over(@snapshots.find(query, sort: order, limit: 1).to_a, :get_snapshot_from_document).first
    end
  end

  def put_commit commit
    ErrorHandler.wrap do
      ConcurrentOperation.new.when(:concurrency_error_detected) do |error|
        query = { '_id.event_source_id' => commit.event_source_id,
                  '_id.sequence'        => commit.sequence }

        committed = @commits.find_one query
        raise DuplicateCommitError if !committed.nil? && committed['headers']['id'] == commit.id
      end
      .when(:other_error_detected) do |error|
        raise StorageError, e.message, e.backtrace
      end
      .execute do
        @commits.insert get_document_for_commit commit
        increment_stream_position_after_commit commit.event_source_id, commit.sequence, commit.events.length
      end
    end
  end

  def put_snapshot snapshot
    return false if snapshot.nil?

    begin
      document = get_document_for_snapshot snapshot
      @snapshots.update document['_id'], document, upsert: true
      increment_stream_position_after_snapshot snapshot
      true
    rescue ::Mongo::OperationFailure
      false
    end
  end

  def mark_commits_as_dispatched commits
    return if commits.empty?

    ErrorHandler.wrap do
      query = {
        '$or' => commits.map do |commit|
          {
            '_id.event_source_id' => commit.event_source_id,
            '_id.sequence'        => commit.sequence
          }
        end }

      modifiers = {
        '$set' => {
          'headers.dispatched' => true },
        '$unset' => {
          'headers.dispatcher_id' => 1 } }

      @commits.update query, modifiers, multi: true
    end
  end

  def take_ownership_of_undispatched_commits dispatcher_id
    ErrorHandler.wrap do
      new_commits_eligible_for_dispatch  = {
        'headers.dispatcher_id' => nil,
        'headers.dispatched'    => false  }

      commits_stuck_in_other_components  = {
        'headers.dispatcher_id'       => { '$ne' => nil },
        'headers.dispatched'          => false,
        'headers.timestamp.as_float'  => Time.now.to_f - 30 }

      query = { '$or' => [
        new_commits_eligible_for_dispatch,
        commits_stuck_in_other_components ] }

      modifiers = {
        '$set' => {
          'headers.dispatcher_id' => dispatcher_id } }

      @commits.update query, modifiers, multi: true
    end
  end

  private

  def get_commit_from_document document
    Commit.new id:              document['headers']['id'],
               commands:        document['body']['commands'].pluck(:symbolize_keys, true),
               duration:        document['headers']['duration'],
               event_source_id: document['_id']['event_source_id'],
               events:          document['body']['events'].pluck(:symbolize_keys, true),
               origin:          document['headers']['origin'].symbolize_keys(true),
               sequence:        document['_id']['sequence'],
               timestamp:       Time.at(document['headers']['timestamp']['as_float']).utc,
               type:            document['headers']['type']
  end

  def get_document_for_commit commit
    {
      '_id' => {
        'event_source_id' => commit.event_source_id,
        'sequence'        => commit.sequence
      },

      'headers' => {
        'id'          => commit.id,
        'type'        => commit.type.to_s,
        'version'     => 1,
        'origin'      => commit.origin,
        'dispatched'  => false,
        'duration'    => commit.duration,
        'timestamp'   => {
          'as_float'    => commit.timestamp.to_f,
          'as_rfc3339'  => commit.timestamp.to_datetime.rfc3339(6)
        }
      },

      'body' => {
        'commands' => commit.commands,
        'events'   => commit.events.each_with_index.map do |event, index|
          event[:headers][:sequence] = commit.sequence + index
          event
        end
      }
    }
  end

  def get_document_for_snapshot snapshot
    {
      '_id' => {
        'event_source_id'  => snapshot.event_source_id,
        'sequence'         => snapshot.sequence
      },
      'headers' => {
        'idempotence_message_ids' => snapshot.idempotence_message_ids,
        'type'                    => snapshot.type,
        'version'                 => snapshot.version
      },
      'body' => snapshot.body
    }
  end

  def get_snapshot_from_document document
    Snapshot.new event_source_id:         document['_id']['event_source_id'],
                 sequence:                document['_id']['sequence'],
                 type:                    document['headers']['type'],
                 version:                 document['headers']['version'],
                 idempotence_message_ids: document['headers']['idempotence_message_ids'],
                 body:                    document['body'].symbolize_keys(true)
  end

  def get_stream_from_document document
    Stream.new document['_id'],
               document['commit_sequence'],
               document['snapshot_sequence']
  end

  def increment_stream_position_after_commit event_source_id, sequence, unsnapshotted
    Thread.fork do
      id = { '_id' => event_source_id }

      modifiers = { '$set' => { 'commit_sequence'   => sequence },
                    '$inc' => { 'snapshot_sequence' => 0,
                                'unsnapshotted'     => unsnapshotted } }

      @streams.update id, modifiers, upsert: true
    end
  end

  def increment_stream_position_after_snapshot snapshot
    id = { '_id' => snapshot.event_source_id }
    stream_commit_sequence = @streams.find_one(id)['commit_sequence']

    modifiers = { '$set' => { 'snapshot_sequence' => snapshot.sequence,
                              'unsnapshotted'     => stream_commit_sequence - snapshot.sequence } }

    @streams.update id, modifiers
  end
end

end
end
