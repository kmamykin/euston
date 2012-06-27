Gem::Specification.new do |s|
  s.name        = 'euston'
  s.version     = '2.0.0'
  s.date        = '2012-06-27'
  s.platform    = RUBY_PLATFORM.to_s == 'java' ? 'java' : Gem::Platform::RUBY
  s.authors     = ['Lee Henson', 'Guy Boertje']
  s.email       = ['lee.m.henson@gmail.com', 'guyboertje@gmail.com']
  s.summary     = %q{event-sourcing.rb}
  s.description = ''
  s.homepage    = 'http://github.com/leemhenson/euston'

  # = MANIFEST =
  s.files = %w[
    Gemfile
    Guardfile
    Rakefile
    euston.gemspec
    lib/euston.rb
    lib/euston/command_handler.rb
    lib/euston/commit.rb
    lib/euston/constant_loader.rb
    lib/euston/constants.rb
    lib/euston/errors.rb
    lib/euston/event_handler.rb
    lib/euston/global_message_handler_map.rb
    lib/euston/marshalling.rb
    lib/euston/message.rb
    lib/euston/message_class_finder.rb
    lib/euston/message_handler.rb
    lib/euston/message_handler_message_map.rb
    lib/euston/message_source.rb
    lib/euston/message_source_history.rb
    lib/euston/message_source_id.rb
    lib/euston/mongo/concurrent_operation.rb
    lib/euston/mongo/config.rb
    lib/euston/mongo/data_store.rb
    lib/euston/mongo/error_handler.rb
    lib/euston/mongo/errors.rb
    lib/euston/mongo/message_bus.rb
    lib/euston/mongo/stream.rb
    lib/euston/mongo/structure_initialiser.rb
    lib/euston/namespaces.rb
    lib/euston/null_logger.rb
    lib/euston/pluck.rb
    lib/euston/snapshot.rb
    lib/euston/specs/event_handler_spec.rb
    lib/euston/specs/have_produced_matcher.rb
    lib/euston/specs/message_source_spec.rb
    lib/euston/uuid.rb
    lib/euston/version.rb
    spec/command_handler_spec.rb
    spec/command_spec.rb
    spec/constant_loader_spec.rb
    spec/data_store/commits_spec.rb
    spec/data_store/scenario_spec.rb
    spec/data_store/snapshots_spec.rb
    spec/event_handler_spec.rb
    spec/event_source/command_invocation_spec.rb
    spec/event_source/command_publishing_spec.rb
    spec/event_source/command_subscription_spec.rb
    spec/event_source/event_invocation_spec.rb
    spec/event_source/event_subscription_spec.rb
    spec/event_source/historical_versioning_spec.rb
    spec/event_source/hydration_spec.rb
    spec/event_source/snapshot_spec.rb
    spec/event_source/state_transition_spec.rb
    spec/event_source/transition_definitions_spec.rb
    spec/factories/book_tee_command.rb
    spec/factories/check_for_slow_play_command.rb
    spec/factories/commit.rb
    spec/factories/event_source_id.rb
    spec/factories/snapshot.rb
    spec/factories/tee_booked_event.rb
    spec/global_message_handler_map_spec.rb
    spec/golf_scenario_mixin.rb
    spec/mongo_spec_mixin.rb
    spec/scenarios/golf_course/command_handlers/weather_station.rb
    spec/scenarios/golf_course/commands/book_tee.rb
    spec/scenarios/golf_course/commands/cancel_tee_booking.rb
    spec/scenarios/golf_course/commands/check_for_slow_play.rb
    spec/scenarios/golf_course/commands/log_score.rb
    spec/scenarios/golf_course/commands/log_temperature.rb
    spec/scenarios/golf_course/commands/start_group.rb
    spec/scenarios/golf_course/event_handlers/email_queue.rb
    spec/scenarios/golf_course/event_sources/scorer.rb
    spec/scenarios/golf_course/event_sources/secretary.rb
    spec/scenarios/golf_course/event_sources/starter.rb
    spec/scenarios/golf_course/events/course_record_broken.rb
    spec/scenarios/golf_course/events/group_playing_slowly.rb
    spec/scenarios/golf_course/events/round_completed.rb
    spec/scenarios/golf_course/events/round_started.rb
    spec/scenarios/golf_course/events/score_logged.rb
    spec/scenarios/golf_course/events/tee_booked.rb
    spec/scenarios/golf_course/events/tee_booking_cancelled.rb
    spec/scenarios/golf_course/events/tee_booking_rejected.rb
    spec/scenarios/golf_course/events/warning_issued_for_slow_play.rb
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
    s.add_development_dependency 'libnotify',   '~> 0.7.2'
  end
end
