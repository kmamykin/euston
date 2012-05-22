module Euston
module Mongo

class Config
  def uri
    @uri ||= 'mongodb://127.0.0.1:27017/?safe=true;fsync=true;w=1;'
  end

  attr_writer :uri
  attr_accessor :database, :logger
end

end
end
