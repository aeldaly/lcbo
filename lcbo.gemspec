# coding: utf-8
require File.expand_path("../lib/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = 'lcbo'
  s.version     = VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Carsten Nielsen', 'Lenard Andal', 'Ahmed El-Daly']
  s.email       = ['aeldaly@developergurus.com']
  s.summary     = %q{A library for parsing HTML pages from http://lcbo.com, http://bcliquorstores.com, http://saq.com}
  s.description = %q{Request and parse product, store, inventory, and product search pages directly from the official LCBO website.}

  s.add_dependency 'typhoeus'      
  s.add_dependency 'nokogiri'      
  s.add_dependency 'unicode_utils'
  s.add_dependency 'stringex'

  s.files         = `git ls-files`.split(?\n)
  s.test_files    = `git ls-files -- {test,spec}/*`.split(?\n)
  s.require_paths = ['lib']
end
