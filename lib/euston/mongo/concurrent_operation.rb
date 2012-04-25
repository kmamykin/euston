module Euston
module Mongo

class ConcurrentOperation
  include Hollywood

  def execute &block
    begin
      yield
    rescue *mongo_error_types_for_current_ruby_platform => e
      if e.message.include? "E11000"
        callback :concurrency_error_detected, e
        raise ConcurrencyError
      else
        callback :other_error_detected
        raise e
      end
    end
  end

  private

  def mongo_error_types_for_current_ruby_platform
    @errors ||= begin
      errors = [ ::Mongo::OperationFailure ]
      errors << NativeException if RUBY_PLATFORM.to_s == 'java'
      errors
    end
  end
end

end
end
