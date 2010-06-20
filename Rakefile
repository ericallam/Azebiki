require "bundler"
Bundler.setup

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)

gemspec = eval(File.read("azebiki.gemspec"))

task :build => "#{gemspec.full_name}.gem"

file "#{gemspec.full_name}.gem" => gemspec.files + ["azebiki.gemspec"] do
  system "gem build azebiki.gemspec"
  system "gem install azebiki-#{Azebiki::VERSION}.gem"
end
