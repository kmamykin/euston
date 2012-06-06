# extracted from Rack
# https://github.com/rack/rack/blob/master/lib/rack/nulllogger.rb

module Euston
  class NullLogger
    include Singleton

    def info(progname = nil, &block);  end
    def debug(progname = nil, &block); end
    def warn(progname = nil, &block);  end
    def error(progname = nil, &block); end
    def fatal(progname = nil, &block); end

    def debug?
      false
    end

    alias_method :info?, :debug?
    alias_method :warn?, :debug?
    alias_method :error?, :debug?
    alias_method :fatal?, :debug?
  end
end
