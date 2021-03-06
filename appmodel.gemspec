# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'appmodel/version'

Gem::Specification.new do |spec|
  spec.name          = "appmodel"
  spec.version       = Appmodel::VERSION
  spec.authors       = ["H20Dragon"]
  spec.email         = ["h20dragon@outlook.com"]

  spec.summary       = %q{Application Modeling - Manage your PageObjects.}
  spec.description   = %q{Simple, scalable pageObject design and modeling.}
  spec.homepage      = "http://github.com/h20dragon."
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
