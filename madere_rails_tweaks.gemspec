# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

Gem::Specification.new do |s|
  s.name = 'madere_rails_tweaks'
  s.summary = 'A set of utilities that Steve Madere finds useful for many rails apps.'
  s.description = 'Modules to include in Models, Controllers etc. Some useful Classes'
  s.email = 'steve@stevemadere.com'
  s.homepage = 'https://github.com/stevemadere/madere_rails_tweaks'
  s.license = 'MIT'
  s.version = '0.0.5'
  s.authors = 'Steve Madere'
  s.files = Dir.glob('{lib}/**/*')
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 1.9.2'
  s.add_dependency 'activesupport'
end
