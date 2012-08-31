if Object.const_defined? 'RSpec'
  RSpec::Matchers.define :have_produced do |number|
    match do |actual|
      get_value(actual) == number
    end

    chain :command  do
      @attribute = :commands
    end

    chain :commands do
      @attribute = :commands
    end

    chain :event do
      @attribute = :events
    end

    chain :events do
      @attribute = :events
    end

    failure_message_for_should do |actual|
      <<-EOS
Expected the message source to have produced #{number} #{@attribute} but it actually produced #{get_value actual}:

#{actual.send(@attribute).each { |attr| puts attr }}
EOS
    end

    def get_value actual
      actual.send(@attribute).size
    end
  end
end
