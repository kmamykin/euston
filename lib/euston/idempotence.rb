module Euston
  module Idempotence
    extend ActiveSupport::Concern

    module InstanceMethods
      def if_unhandled obj, headers
        return if obj._history.include? headers.id

        obj._history << headers.id

        unless headers.source_message.nil? || obj._history.include?(headers.source_message[:headers][:id])
          obj._history << headers.source_message[:headers][:id]
        end

        yield
      end

      def if_exists_and_unhandled document_type, id, headers
        document = document_type.find id

        if_unhandled document, headers do
          yield document
        end
      end
    end
  end
end
