require 'ap'
require 'require_all'
require 'euston'
require 'ffaker'
require 'cranky'
require 'ostruct'
require 'recursive_open_struct'

undef type if RUBY_PLATFORM.to_s == 'java'

require_rel 'factories'
require_rel 'scenarios'

require 'golf_scenario_mixin'
require 'mongo_spec_mixin'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.include GolfScenarioMixin, :golf
  config.include MongoSpecMixin, :mongo
end

class Object
  def tapout
    tap { |x| ap x }
  end
end
