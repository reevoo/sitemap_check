# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "sitemap_check/version"

Gem::Specification.new do |spec|
  spec.name          = "sitemap_check"
  spec.version       = SitemapCheck::VERSION
  spec.authors       = ["Ed Robinson"]
  spec.email         = ["ed@reevoo.com"]

  spec.summary       = "Check for broken links in your sitemap"
  spec.homepage      = "https://github.com/reevoo/sitemap_check"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(/^spec\//) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri", "~> 1.7"
  spec.add_dependency "typhoeus", "~> 1.1"
  spec.add_dependency "colorize", "~> 0.8"
  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "rspec", "~> 3.5"
  spec.add_development_dependency "reevoocop"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "codeclimate-test-reporter"
end
