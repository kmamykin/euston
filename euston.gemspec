Gem::Specification.new do |s|
  s.name        = 'euston'
  s.version     = '2.0.0'
  s.date        = '2012-02-02'
  s.platform    = RUBY_PLATFORM.to_s == 'java' ? 'java' : Gem::Platform::RUBY
  s.authors     = ['Lee Henson', 'Guy Boertje']
  s.email       = ['lee.m.henson@gmail.com', 'guyboertje@gmail.com']
  s.summary     = %q{event-sourcing.rb}
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

  s.add_dependency 'activemodel',               '~> 3.1.0'
  s.add_dependency 'activesupport',             '~> 3.1.0'
  s.add_dependency 'enumeradical',              '~> 0.9.0'
  s.add_dependency 'hash_symbolizer',           '~> 1.0.1'
  s.add_dependency 'hollywood',                 '~> 1.0.0'

  if RUBY_PLATFORM.to_s == 'java'
    s.add_dependency 'json-jruby',              '~> 1.5.0'
    s.add_dependency 'jmongo',                  '~> 1.1.1'
  else
    s.add_dependency 'bson',                    '>= 1.3.0'
    s.add_dependency 'bson_ext',                '>= 1.3.0'
    s.add_dependency 'json',                    '~> 1.5.0'
    s.add_dependency 'mongo',                   '>= 1.3.0'
    s.add_dependency 'uuid',                    '~> 2.3.0'
  end

  s.add_development_dependency 'awesome_print',         '~> 1.0.0'
  s.add_development_dependency 'cranky',                '~> 0.3.1'
  s.add_development_dependency 'ffaker',                '~> 1.14.0'
  s.add_development_dependency 'fuubar',                '~> 1.0.0'
  s.add_development_dependency 'guard',                 '~> 1.0.1'
  s.add_development_dependency 'guard-rspec',           '~> 0.7.0'
  s.add_development_dependency 'rake',                  '~> 0.9.0'
  s.add_development_dependency 'recursive-open-struct', '~> 0.2.1'
  s.add_development_dependency 'require_all',           '~> 1.2.0'
  s.add_development_dependency 'rspec',                 '~> 2.10.0'

  if RbConfig::CONFIG['host_os'] =~ /darwin/i
    s.add_development_dependency 'rb-fsevent',  '~> 0.9.0'
    s.add_development_dependency 'growl',       '~> 1.0.3'
  else
    s.add_development_dependency 'rb-inotify',  '~> 0.8.8'
    s.add_development_dependency 'libnotify'    '~> 0.7.2'
  end
end
