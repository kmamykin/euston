Gem::Specification.new do |s|
  s.name        = 'euston'
  s.version     = '1.2.7'
  s.date        = '2012-02-02'
  s.platform    = RUBY_PLATFORM.to_s == 'java' ? 'java' : Gem::Platform::RUBY
  s.authors     = ['Lee Henson', 'Guy Boertje']
  s.email       = ['lee.m.henson@gmail.com', 'guyboertje@gmail.com']
  s.summary     = %q{Cqrs tooling.}
  s.description = ''
  s.homepage    = 'http://github.com/leemhenson/euston'

  # = MANIFEST =
  s.files = %w[
    Gemfile
    Rakefile
    euston.gemspec
    lib/euston.rb
    lib/euston/aggregate_command_map.rb
    lib/euston/aggregate_root.rb
    lib/euston/aggregate_root_dsl_methods.rb
    lib/euston/aggregate_root_private_method_names.rb
    lib/euston/command.rb
    lib/euston/command_bus.rb
    lib/euston/command_handler.rb
    lib/euston/command_handler_private_method_names.rb
    lib/euston/command_headers.rb
    lib/euston/errors.rb
    lib/euston/event.rb
    lib/euston/event_handler.rb
    lib/euston/event_handler_private_method_names.rb
    lib/euston/event_headers.rb
    lib/euston/null_logger.rb
    lib/euston/repository.rb
    lib/euston/version.rb
    spec/aggregate_command_map_spec.rb
    spec/aggregate_root_samples.rb
    spec/aggregate_root_spec.rb
    spec/command_headers_spec.rb
    spec/spec_helper.rb
  ]
  # = MANIFEST =

  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }

  s.add_dependency 'activemodel',         '>= 3.0.10'
  s.add_dependency 'activesupport',       '>= 3.0.10'

  s.add_development_dependency 'fuubar',  '~> 0.0.0'
  s.add_development_dependency 'rake',    '~> 0.9.2'
  s.add_development_dependency 'rspec',   '~> 2.6.0'
  s.add_development_dependency 'uuid',    '~> 2.3.0'
end
