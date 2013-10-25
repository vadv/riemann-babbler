# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'riemann/babbler/version'

Gem::Specification.new do |spec|
  spec.name        = 'riemann-babbler'
  spec.version     = Riemann::Babbler::VERSION
  spec.authors     = ['Vasiliev Dmitry']
  spec.email       = ['vadv.mkn@gmail.com']
  spec.description = %q{Monitoring tool for riemann}
  spec.summary     = %q{Monitoring tool for riemann server, aka plugin manager}
  spec.homepage    = 'https://github.com/vadv/riemann-babbler'
  spec.license     = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = %w(lib)

  spec.add_dependency 'riemann-client'
  spec.add_dependency 'trollop'
  spec.add_dependency 'rest-client'
  spec.add_dependency 'sys-filesystem'
  spec.add_dependency 'docile'
  spec.add_dependency 'configatron'
  spec.add_dependency 'net-http-server'


  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'pry'
end
