# encoding: utf-8

require 'rake/extensiontask'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "mamba-refactor"
  gem.homepage = "http://github.com/rogwfu/mamba-refactor"
  gem.license = "MIT"
  gem.summary = %Q{Mamba Fuzzer Refactor}
  gem.description = %Q{File format fuzzing framework including genetic algorithms and a distributed fuzzing environment.  The refactor improves by leveraging thor.}
  gem.email = "roger.seagle@gmail.com"
  gem.authors = ["Roger Seagle, Jr."]
  # dependencies defined in Gemfile
  gem.extensions          = FileList['ext/**/extconf.rb']
end
Jeweler::RubygemsDotOrgTasks.new

Rake::ExtensionTask.new('fuzzrnd') do |ext|
  ext.lib_dir = File.join 'lib', 'mamba-refactor'
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


require 'yard'
YARD::Rake::YardocTask.new
