$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "os_tools/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "os_tools"
  s.version     = OsTools::VERSION
  s.authors     = ['Jason Lefley']
  s.email       = ['jason@oneslate.com']
  s.homepage    = 'http://oneslate.com'
  s.summary     = 'PG DB Utils'
  s.description = 'PG DB Utils'

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency 'rails', '~> 4.0.0'
  s.add_dependency 'sequel_postgresql_triggers'
  s.add_dependency 'sequel_pg'
  s.add_dependency 'sequel-rails'

  s.add_development_dependency 'rspec-rails'
end
