module Euston
  class Command
    include ActiveModel::Validations

    def initialize body
      @headers = { :id => Uuid.generate,
                   :type => self.class.to_s.split('::').pop.underscore.to_sym }
      @body = body
    end

    def read_attribute_for_validation key
      @body[key]
    end

    def to_hash
      { :headers => @headers.merge(:version => version), :body => @body }
    end

    def id
      @headers[:id]
    end

    def version
      1
    end
  end
end
