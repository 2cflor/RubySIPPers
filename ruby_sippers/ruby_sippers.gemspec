# -*- encoding: utf-8 -*-
require File.expand_path('../lib/ruby_sippers/version', __FILE__)

Gem::Specification.new do |gem|
  gem.version       = RubySippers::VERSION
  gem.name        = 'ruby_sippers'
  gem.date        = '2013-05-10'
  gem.summary     = "A way to automate SIP conversations"
  gem.description = "RubySIPpers is built on top of SIPp and creates and initiates SIP conversations defined within a simple DSL"
  gem.authors     = ["Christian Flor", "John Crawford", "Tye Mcqueen", "Ambrose Sterr"]
  gem.email       = '2chris.flor@gmail.com'
  gem.files       = ["all_the_files"]
  gem.homepage    = 'https://github.com/2cflor/RubySIPPers'
  gem.files         = `git ls-files`.split($\)
  gem.require_paths = ["lib"]
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.add_development_dependency 'rake'
  gem.add_dependency('sinatra')
  gem.add_dependency('nokogiri')
end
