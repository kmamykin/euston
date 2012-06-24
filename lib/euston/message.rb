module Euston
  class Message
    def self.version version, &block
      raise 'Version numbers must be specified as an Integer' unless version.is_a?(Integer)

      namespaces = self.to_s.split '::'
      class_name = namespaces.pop
      constant_name = "#{class_name}_v#{version}"
      message_type = class_name.underscore

      namespace = Object

      while (ns = namespaces.shift)
        namespace = namespace.const_get ns
      end

      return if namespace.const_defined? constant_name.to_sym

      klass = Class.new do
        extend ActiveModel::Naming
        include ActiveModel::Validations
        include ActiveModel::Validations::Callbacks
        include Euston::VersionedMessage

        after_validation do
          id = @headers[:id]

          unless id.is_a?(String) && id =~ /^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$/
            errors[:base] << "Id specified in the headers of a #{class_name} message must be a string Uuid"
          end
        end

        def self.headers hash
          MessageBuilder.new self, hash
        end

        def to_hash
          { headers: @headers, body: @body }
        end

        def read_attribute_for_validation key
          @body[key]
        end
      end

      klass.class_eval <<-EOC, __FILE__, __LINE__ + 1
        def initialize headers = nil, body = nil
          if !headers.nil? && body.nil?
            headers, body = nil, headers
          end

          raise 'Headers must be supplied to #{class_name} messages as a Hash' unless headers.nil? || headers.is_a?(Hash)
          raise 'Body must be supplied to #{class_name} messages as a Hash'    unless body.nil?    || body.is_a?(Hash)

          @headers = { id: Uuid.generate }
          @headers.merge! Marshal.load(Marshal.dump headers) unless headers.nil?
          @headers.merge! type: :#{message_type}, version: #{version}

          @body = body || {}
        end
      EOC

      klass.class_exec &block

      namespace.const_set constant_name, klass
      versions[version] = klass
    end

    def self.v version
      versions[version]
    end

    def self.versions
      @versions ||= {}
    end
  end

  class MessageBuilder
    def initialize type, headers
      @type = type
      @headers = headers
    end

    def body hash = {}
      @type.new @headers, hash
    end
  end

  class Command < Message; end
  class Event   < Message; end
  module VersionedMessage; end
end
