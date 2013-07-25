# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'health_status/version'

Gem::Specification.new do |spec|
  spec.name          = "health_status"
  spec.version       = HealthStatus::VERSION
  spec.authors       = ["Ryosuke IWANAGA"]
  spec.email         = ["riywo.jp@gmail.com"]
  spec.description   = %q{Health status API server}
  spec.summary       = %q{API server to store and visualize applications' health status}
  spec.homepage      = "https://github.com/riywo/health_status"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'sinatra'
  spec.add_dependency 'sinatra-contrib'
  spec.add_dependency 'activerecord'
  spec.add_dependency 'sinatra-activerecord'
  spec.add_dependency 'sqlite3'
  spec.add_dependency 'vegas'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency 'tapp'
  spec.add_development_dependency 'rake'
end
