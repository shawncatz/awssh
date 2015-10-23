# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'awssh/version'

Gem::Specification.new do |spec|
  spec.name          = "awssh"
  spec.version       = Awssh::Version::STRING
  spec.authors       = ["Shawn Catanzarite"]
  spec.email         = ["me@shawncatz.com"]
  spec.summary       = %q{aws ssh wrapper}
  spec.description   = %q{aws ssh wrapper}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  # spec.add_dependency 'fog', '~> 1.30.0'
  spec.add_dependency 'aws-sdk', '~> 2.1.31'
  spec.add_dependency 'dotenv', '~> 2.0.1'
  spec.add_dependency 'activesupport'

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
