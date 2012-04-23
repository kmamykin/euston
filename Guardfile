# More info at https://github.com/guard/guard#readme

notification :growl

guard 'rspec', version: 2, cli: '--colour --format Fuubar --tty -r ./spec/spec_helper.rb' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})             { "spec" }
  watch(%r{^spec/scenarios/(.+)\.rb$})  { "spec" }
  watch('spec/spec_helper.rb')          { "spec" }
end

