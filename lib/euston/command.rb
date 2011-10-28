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

    def id= value
      @headers[:id] = value
    end

    def publishing_user_id
      @headers[:user_id]
    end

    def publishing_user_id= value
      @headers[:user_id] = value
    end

    def read_attribute_for_validation key
      match = /^__(.*)/.match(key.to_s)

      if match.nil?
        @body[key]
      else
        headers[match[1].to_sym]
      end
    end

    def type
      @headers[:type]
    end

    def to_hash
      { :headers => headers, :body => @body }
    end

    def version
      1
    end

    attr_reader :body

    validates :__id,        :presence => true, :format => { :with => /^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$/ }
    validates :__type,      :presence => true
    validates :__version,   :presence => true, :numericality => { :greater_than => 0, :only_integer => true }
  end
end
