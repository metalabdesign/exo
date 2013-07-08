# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'exo/version'

Gem::Specification.new do |spec|
  spec.name          = "exo"
  spec.version       = Exo::VERSION
  spec.authors       = ["Jason Webster"]
  spec.email         = ["jason@metalabdesign.com"]
  spec.description   = "A Thorax/Backbone UI library"
  spec.summary       = "A Thorax/Backbone UI library"
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
