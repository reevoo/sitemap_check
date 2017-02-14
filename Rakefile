require "bundler/gem_tasks"
require "reevoocop/rake_task"
require "rspec/core/rake_task"

ReevooCop::RakeTask.new(:reevoocop)
RSpec::Core::RakeTask.new(:spec)

DOCKER_REPO = "quay.io/reevoo/sitemap_check"

task default: [:spec, :reevoocop]
task release: [:spec, :reevoocop]
task build:   [:spec, :reevoocop]

task :release do
  sh "docker build -t #{DOCKER_REPO}:#{SitemapCheck::VERSION} ."
  sh "docker build -t #{DOCKER_REPO}:latest ."
  sh "docker push #{DOCKER_REPO}:#{SitemapCheck::VERSION}"
  sh "docker push #{DOCKER_REPO}:latest"
end
