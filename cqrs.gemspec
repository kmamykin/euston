# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "cqrs/version"

Gem::Specification.new do |s|
  s.name        = "cqrs"
  s.version     = Cqrs::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Lee Henson']
  s.email       = ['lee.m.henson@gmail.com']
  s.homepage    = ""
  s.summary     = %q{}
  s.description = %q{Modifies and expands on the ideas initially prototyped in cavalle's banksimplistic project
(http://github.com/cavalle/banksimplistic), itself an implementation of ideas presented in Mark Nijhof's Fohjin
project (http://github.com/MarkNijhof/Fohjin). See also dddcqrs and ncqrs google groups, and cqrsinfo.com}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'activesupport', '~> 3.0'
  s.add_dependency 'uuid', '~> 2.3'
end
