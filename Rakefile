require 'bundler/gem_tasks'
require 'reevoocop/rake_task'
require 'rspec/core/rake_task'

ReevooCop::RakeTask.new(:reevoocop)
RSpec::Core::RakeTask.new(:spec)

task default: [:spec, :reevoocop]
task release: [:spec, :reevoocop]
task build:   [:spec, :reevoocop]
