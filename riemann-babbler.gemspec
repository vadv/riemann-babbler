# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'riemann/version'

Gem::Specification.new do |s|
  s.name        = "riemann-babbler"
  s.version     = Riemann::Babbler::VERSION
  s.authors     = ["Vasiliev D.V."]
  s.email       = %w(vadv.mkn@gmail.com)
  s.homepage    = "https://github.com/vadv/riemann-babbler"
  s.summary     = %q{Riemann health cheker.}
  s.description = %q{Some plugins mannager for riemann.}
  s.licenses    = %w(MIT)
  
  s.add_dependency('riemann-client')
  s.add_dependency('configatron')
  s.add_dependency('logger')

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = %w(lib)
end
