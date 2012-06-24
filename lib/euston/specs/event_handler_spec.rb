module Euston
  module EventHandlerSpec
    extend ::ActiveSupport::Concern
    extend ::RSpec::Matchers::DSL if Object.const_defined? 'RSpec'

    included do
      private

      def run_scenario
        begin
          handler = handler_type.new

          ([@history] + [@incoming_events]).flatten.compact.each do |event|
            handler.consume(event.is_a?(Hash) ? event : event.to_hash)
          end
        rescue => e
          if @expect_error
            @exception_caught = e
          else
            raise e
          end
        end
      end
    end

    module ClassMethods
      def error_raised &block
        describe 'the error raised' do
          before  { @expect_error = true }

          subject do
            @exception_caught
          end

          instance_eval(&block) if block_given?
        end
      end

      def history &block
        before do
          @history ||= []
          new_history = instance_eval &block
          @history.push *([new_history].flatten.compact)
        end
      end

      def incoming_events &block
        before do
          @incoming_events ||= []
          new_events = instance_eval &block
          @incoming_events.push *([new_events].flatten.compact)
        end
      end

      def sut &block
        before { @sut = block }
      end

      def rescue_error
        before do
          @rescue_error = true
        end
      end
    end
  end
end
