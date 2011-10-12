module Euston
  class Command
    include ActiveModel::Validations

    def initialize body, dispatch_at = nil
      @headers = { :id => Uuid.generate,
                   :type => self.class.to_s.split('::').pop.underscore.to_sym }

      @body = body
      @headers[:dispatch_at] = dispatch_at unless dispatch_at.nil?
    end

    def headers
      @headers.merge :version => version
    end

    def id
      @headers[:id]
    end

    def read_attribute_for_validation key
      @body[key]
    end

    def to_hash
      { :headers => headers, :body => @body }
    end

    def version
      1
    end

    attr_reader :body
  end
end
