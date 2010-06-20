require File.expand_path("../lib/azebiki/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "azebiki"
  s.version     = Azebiki::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Eric Allam"]
  s.email       = ["eric@envylabs.com"]
  s.homepage    = "http://github.com/rubymaverick/azebiki"
  s.summary     = "A DSL for validating HTML"
  s.description = ""

  s.required_rubygems_version = ">= 1.3.6"

  # lol - required for validation
  s.rubyforge_project         = "azebiki"

  # If you have other dependencies, add them here
  s.add_dependency "webrat"
  # s.add_dependency "another", "~> 1.2"

  # If you need to check in files that aren't .rb files, add them here
  s.files        = Dir["{lib}/**/*.rb", "bin/*", "LICENSE", "*.md"]
  s.require_path = 'lib'

  # If you need an executable, add it here
  # s.executables = ["azebiki"]

  # If you have C extensions, uncomment this line
  # s.extensions = "ext/extconf.rb"
end
