module Euston
module Mongo

class ErrorHandler
  def self.wrap &block
    begin
      yield block
    rescue ::Mongo::ConnectionError => e
      raise StorageUnavailableError, e.to_s, e.backtrace
    rescue ::Mongo::MongoDBError => e
      raise StorageError, e.to_s, e.backtrace
    end
  end
end

end
end
