# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "anlas_import/version"

Gem::Specification.new do |s|

  s.name              = 'anlas_import'
  s.version           = AnlasImport::VERSION
  s.platform          = Gem::Platform::RUBY
  s.authors           = ['redfield', 'Tyralion']
  s.email             = ['info@dancingbytes.ru']
  s.homepage          = 'https://github.com/dancingbytes/anlas_import'
  s.summary           = 'Import from 1c (xml) to mongodb.'
  s.description       = 'Import from 1c (xml) to mongodb.'

  s.files             = `git ls-files`.split("\n")
  s.test_files        = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.extra_rdoc_files  = ['README.md']
  s.require_paths     = ['lib']

  s.licenses          = ['BSD']

  s.add_dependency 'railties', '>= 3.0.0'
  s.add_dependency 'nokogiri', '~> 1.5.0'
  s.add_dependency 'zip'
  s.add_dependency 'logger'

end