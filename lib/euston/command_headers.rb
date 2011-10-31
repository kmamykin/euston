module Euston
  class CommandHeaders

    BASE_KEYS = [:id, :type, :version]

    def initialize hash
      arg_errors = []
      BASE_KEYS.each do |arg|
        arg_errors << arg unless hash.has_key?(arg)
      end
      raise Errors::CommandHeadersArgumentError.new("Missing args: #{arg_errors.join(", ")}") if arg_errors.size > 0
      @headers = {}.merge(hash)
      @headers[:type] = @headers[:type].to_sym
      @headers_keys = @headers.keys
    end

    def [] name
      @headers[name.to_sym]
    end

    # only use method missing for uncommon attributes
    def id()      @headers[:id]; end
    def type()    @headers[:type]; end
    def version() @headers[:version]; end

    def to_hash
      @headers.dup
    end

    def ==(other)
      @headers == other.to_hash
    end

    def self.from_hash hash
      self.new hash
    end

    def to_s
      "#{id} #{type} (v#{version})"
    end

    def method_missing(name,*args,&block)
      n = name.to_sym
      is_dynamic_method?(n) ? @headers[n] : super
    end

    # >= 1.9.2
    def respond_to_missing?(name, incl_private)
      is_dynamic_method?(name.to_sym) || super
    end

    private

    def is_dynamic_method? name
      (@headers_keys - BASE_KEYS).include?(name)
    end
  end
end
