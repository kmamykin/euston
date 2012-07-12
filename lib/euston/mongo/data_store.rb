module Euston
module Mongo

class DataStore
  def self.build &block
    config = Config.new

    yield config

    options = {}
    options.merge!(:logger => config.logger) unless config.logger.nil?

    connection = ::Mongo::Connection.from_uri config.uri, options
    DataStore.new connection.db config.database
  end

  def initialize database
    Euston::Mongo::StructureInitialiser.new(database).prepare

    @commits    = database.collection 'commits'
    @snapshots  = database.collection 'snapshots'
    @streams    = database.collection 'streams'

    @ascending  = ::Mongo::ASCENDING
    @descending = ::Mongo::DESCENDING
  end

  def already_processed_message? message_source_id, message_id
    ErrorHandler.wrap do
      query = get_document_id_hash_from_message_source_id(message_source_id, '_id.').merge('headers.origin.headers.id' => message_id)
      !@commits.find_one(query).nil?
    end
  end

  def find_commits options = {}
    ErrorHandler.wrap do
      options = {
        min_sequence: 0,
        max_sequence: FIXNUM_MAX,
        min_timestamp: 0,
        max_timestamp: FIXNUM_MAX
      }.merge options

      [:min_timestamp, :max_timestamp].each do |sym|
        options[sym] = options[sym].to_f unless options[sym].is_a? Float
      end

      order = if options.has_key? :message_source_id
        [ '_id.sequence', @ascending ]
      else
        [ 'headers.timestamp.as_float', @ascending ]
      end

      query = {
        '$or' => [{
            'body.events.headers.sequence' => {
              '$gte' => options[:min_sequence],
              '$lte' => options[:max_sequence] },
          }, {
            '_id.sequence' => {
              '$gte' => options[:min_sequence],
              '$lte' => options[:max_sequence] }
        }],

        'headers.timestamp.as_float' => {
          '$gte' => options[:min_timestamp],
          '$lte' => options[:max_timestamp]
        }
      }

      if options.has_key? :message_source_id
        query['_id.id'] = options[:message_source_id].id
        query['_id.type'] = options[:message_source_id].type
      end

      map_over @commits.find(query, sort: order, batch_size: 100).to_a, :get_commit_from_document
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

  def find_snapshottable_stream snapshotter_id
    ErrorHandler.wrap do
      query = { snapshotter_id: snapshotter_id }

      stream = @streams.find_one(query)
      stream = get_stream_from_document stream unless stream.nil?
      stream
    end
  end

  def find_snapshots message_source_id
    ErrorHandler.wrap do
      query = get_document_id_hash_from_message_source_id message_source_id, '_id.'
      order = [ '_id.sequence', @ascending ]

      map_over @snapshots.find(query, sort: order).to_a, :get_snapshot_from_document
    end
  end

  def find_streams_to_snapshot max_threshold
    ErrorHandler.wrap do
      query = { 'unsnapshotted' => { '$gte' => max_threshold } }
      order = [ 'unsnapshotted', @descending ]

      map_over @streams.find(query, sort: order).to_a, :get_stream_from_document
    end
  end

  def get_history message_source_id
    snapshot = get_snapshot message_source_id

    commit_criteria = { message_source_id: message_source_id }
    commit_criteria[:min_sequence] = snapshot.sequence + 1 unless snapshot.nil?
    commits = find_commits commit_criteria

    return nil if snapshot.nil? && commits.empty?

    MessageSourceHistory.new id: message_source_id.id, commits: commits, snapshot: snapshot, type: message_source_id.type
  end

  def get_snapshot message_source_id, max_sequence = FIXNUM_MAX
    ErrorHandler.wrap do
      query = {
        '_id' => {
          '$gt' => get_document_id_hash_from_message_source_id(message_source_id).merge('sequence' => nil),
          '$lte' => get_document_id_hash_from_message_source_id(message_source_id).merge('sequence' => max_sequence) } }

      order = [ '_id', @descending ]

      map_over(@snapshots.find(query, sort: order, limit: 1).to_a, :get_snapshot_from_document).first
    end
  end

  def put_commit commit
    ErrorHandler.wrap do
      ConcurrentOperation.new.when(:concurrency_error_detected) do |error|
        query = get_document_id_hash_from_message_source_id(commit.message_source_id, '_id.').merge('_id.sequence' => commit.sequence)
        committed = @commits.find_one query
        raise DuplicateCommitError if !committed.nil? && committed['headers']['id'] == commit.id
      end
      .when(:other_error_detected) do |error|
        raise StorageError, e.message, e.backtrace
      end
      .execute do
        @commits.insert get_document_for_commit commit
        increment_stream_position_after_commit commit
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
          get_document_id_hash_from_message_source_id(commit.message_source_id, '_id.').merge('_id.sequence' => commit.sequence)
        end }

      modifiers = {
        '$set' => {
          'headers.dispatched' => true },
        '$unset' => {
          'headers.dispatcher_id' => 1 } }

      @commits.update query, modifiers, multi: true
    end
  end

  def take_ownership_of_snapshottable_stream max_threshold, snapshotter_id
    ErrorHandler.wrap do
      new_streams_eligible_for_snapshotting = {
        snapshottable: true,
        snapshotter_id: nil,
        unsnapshotted: { '$gte' => max_threshold } }

      streams_stuck_in_other_components = {
        unsnapshotted: { '$gte' => max_threshold },
        snapshotter_id: { '$ne' => nil },
        'snapshotting_at.as_float' => { '$lt' => Time.now.to_f - 30 } }

      query = { '$or' => [
        new_streams_eligible_for_snapshotting,
        streams_stuck_in_other_components ] }

      modifiers = {
        '$set' => {
          snapshotter_id: snapshotter_id,
          snapshotting_at: {
            as_float: Time.now.to_f,
            as_rfc3339: Time.now.to_datetime.rfc3339(6) } } }

      @streams.update query, modifiers, multi: false
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

  def async_job &block
    if RUBY_PLATFORM.to_s == 'java'
      Thread.fork do
        yield
      end
    else
      yield
    end
  end

  def get_commit_from_document document
    Commit.new id:              document['headers']['id'],
               commands:        document['body']['commands'].pluck(:symbolize_keys, true),
               duration:        document['headers']['duration'],
               message_source_id: get_message_source_id_from_document_id_hash(document),
               events:          document['body']['events'].pluck(:symbolize_keys, true),
               origin:          document['headers']['origin'].symbolize_keys(true),
               sequence:        document['_id']['sequence'],
               timestamp:       Time.at(document['headers']['timestamp']['as_float']).utc
  end

  def get_document_for_commit commit
    {
      '_id' => get_document_id_hash_from_message_source_id(commit.message_source_id).merge('sequence' => commit.sequence),

      'headers' => {
        'id'          => commit.id,
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
      '_id' => get_document_id_hash_from_message_source_id(snapshot.message_source_id).merge('sequence' => snapshot.sequence),

      'headers' => {
        'version'     => snapshot.version,
        'duration'    => snapshot.duration,
        'timestamp'   => {
          'as_float'    => snapshot.timestamp.to_f,
          'as_rfc3339'  => snapshot.timestamp.to_datetime.rfc3339(6)
        }
      },
      'body' => snapshot.body
    }
  end

  def get_document_id_hash_from_message_source_id message_source_id, prefix = ''
    { "#{prefix}id"    => message_source_id.id,
      "#{prefix}type"  => message_source_id.type }
  end

  def get_message_source_id_from_document_id_hash document
    MessageSourceId.new document['_id']['id'], document['_id']['type']
  end

  def get_snapshot_from_document document
    Snapshot.new message_source_id: get_message_source_id_from_document_id_hash(document),
                 sequence:        document['_id']['sequence'],
                 version:         document['headers']['version'],
                 body:            document['body'].symbolize_keys(true)
  end

  def get_stream_from_document document
    Stream.new message_source_id:   get_message_source_id_from_document_id_hash(document),
               commit_sequence:   document['commit_sequence'],
               snapshot_sequence: document['snapshot_sequence']
  end

  def increment_stream_position_after_commit commit
    async_job do
      id = { '_id' => get_document_id_hash_from_message_source_id(commit.message_source_id) }

      modifiers = { '$set' => { 'commit_sequence'   => commit.sequence,
                                'snapshottable'     => commit.message_source_id.klass.message_map.has_snapshot_metadata? },
                    '$inc' => { 'snapshot_sequence' => 0,
                                'unsnapshotted'     => commit.events.length } }

      @streams.update id, modifiers, upsert: true
    end
  end

  def increment_stream_position_after_snapshot snapshot
    id = { '_id' => get_document_id_hash_from_message_source_id(snapshot.message_source_id) }
    stream_commit_sequence = @streams.find_one(id)['commit_sequence']

    modifiers = { '$set'   => { 'snapshot_sequence' => snapshot.sequence,
                                'unsnapshotted'     => stream_commit_sequence - snapshot.sequence },
                  '$unset' => { 'snapshotter_id'    => 1,
                                'snapshotting_at'   => 1 } }

    @streams.update id, modifiers
  end
end

end
end
