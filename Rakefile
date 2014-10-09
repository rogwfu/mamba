# encoding: utf-8
require 'rake'
require 'rake/extensiontask'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "mamba"
  gem.homepage = "http://github.com/rogwfu/mamba"
  gem.license = "MIT"
  gem.summary = %Q{Mamba Fuzzer}
  gem.description = %Q{File format fuzzing framework including genetic algorithms and a distributed fuzzing environment.  The refactor improves by leveraging thor.}
  gem.email = "roger.seagle@gmail.com"
  gem.authors = ["Roger Seagle, Jr."]
  gem.required_ruby_version = '>= 1.9.3'

  # dependencies defined in Gemfile
  gem.add_dependency("thor", "=0.14.6")
  gem.add_dependency("daemons", "=1.1.3")
  gem.add_dependency("uuidtools", "=2.1.2")
  gem.add_dependency("rubyzip", "=0.9.4")
  gem.add_dependency("log4r", "=1.1.9")
  gem.add_dependency("directory_watcher", "=1.4.0")
  gem.add_dependency("bson_ext", "=1.4.0")
  gem.add_dependency("mongo", "=1.3.1")
  gem.add_dependency("amqp", "=0.7.1")
  gem.add_dependency("hpricot", "=0.8.4")
  gem.add_dependency("plympton", "~> 1.1.0")
  gem.add_dependency("amatch", "=0.2.6")
  gem.add_dependency('nokogiri', '~> 1.6.0')

  # Extensions
  gem.extensions          = FileList['ext/**/extconf.rb']
end
Jeweler::RubygemsDotOrgTasks.new

Rake::ExtensionTask.new('fuzzrnd') do |ext|
  ext.lib_dir = File.join 'lib', 'mamba'
end

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end
Rake::Task[:spec].prerequisites << :compile

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

# Rake Task for building yard doc
require 'yard'
YARD::Rake::YardocTask.new do |t|
	t.options = ['--exclude', 'bin/*']
end

