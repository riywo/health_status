# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'health_status/version'

Gem::Specification.new do |gem|
  gem.name          = "health_status"
  gem.version       = HealthStatus::VERSION
  gem.authors       = ["riywo"]
  gem.email         = ["riywo.jp@gmail.com"]
  gem.description   = %q{API server to store and visualize applications' health status}
  gem.summary       = %q{Health status API server}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'sinatra'
  gem.add_dependency 'activerecord'
  gem.add_dependency 'sinatra-activerecord'
  gem.add_dependency 'sqlite3'
  gem.add_dependency 'vegas'

  gem.add_development_dependency 'tapp'
  gem.add_development_dependency 'rake'
end
