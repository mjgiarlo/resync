require File.expand_path('../lib/resync/version', __FILE__)

spec = Gem::Specification.new do |spec|
  spec.name = 'resync'
  spec.version = Resync::VERSION
  spec.summary = 'ResourceSync generators for Ruby'
  spec.description = 'ResourceSync generators for Ruby'

  spec.authors << 'Michael J. Giarlo'
  spec.email = 'leftwing@alumni.rutgers.edu'
  spec.homepage = 'http://github.com/mjgiarlo/resync'

  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'nokogiri'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'rails', '~> 4.0.0'

  spec.add_dependency 'sitemap'

  spec.files = Dir['{lib,docs}/**/*'] + ['README.md', 'LICENSE', 'Rakefile', 'resync.gemspec']
  spec.test_files = Dir['test/**/*']
  spec.require_paths = ['lib']
end
