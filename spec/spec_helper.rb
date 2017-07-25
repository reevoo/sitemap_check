# frozen_string_literal: true
$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "pry"
require "simplecov"

SimpleCov.start do
  minimum_coverage 100
end

def capture_stdout
  real_stdout = $stdout
  $stdout = StringIO.new
  yield
  $stdout.string
ensure
  $stdout = real_stdout
end

def with_env(env)
  old_env = {}
  env.each do |var, val|
    old_env[var] = ENV[var]
    ENV[var] = val
  end

  yield

  old_env.each do |var, val|
    ENV[var] = val
  end
end
