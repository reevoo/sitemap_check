# frozen_string_literal: true
require "bundler/gem_tasks"
require "reevoocop/rake_task"
require "rspec/core/rake_task"

ReevooCop::RakeTask.new(:reevoocop)
RSpec::Core::RakeTask.new(:spec)

DOCKER_REPO = "quay.io/reevoo/sitemap_check"

task default: %i[spec reevoocop]
task release: %i[spec reevoocop]
task build:   %i[spec reevoocop]

task :release do
  Rake::Task["docker:release"].invoke
end

namespace :docker do
  task :build do
    sh "docker build --build-arg VERSION=#{SitemapCheck::VERSION} -t #{DOCKER_REPO}:#{SitemapCheck::VERSION} ."
  end

  task release: :build do
    sh "docker tag #{DOCKER_REPO}:#{SitemapCheck::VERSION} #{DOCKER_REPO}:latest"
    sh "docker push #{DOCKER_REPO}:#{SitemapCheck::VERSION}"
    sh "docker push #{DOCKER_REPO}:latest"
  end
end

