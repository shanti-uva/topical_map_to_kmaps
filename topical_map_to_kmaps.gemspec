$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "topical_map_to_kmaps/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "topical_map_to_kmaps"
  s.version     = TopicalMapToKmaps::VERSION
  s.authors     = ["TODO: Your name"]
  s.email       = ["TODO: Your email"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of TopicalMapToKmaps."
  s.description = "TODO: Description of TopicalMapToKmaps."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.0"
  # s.add_dependency "jquery-rails"
  s.add_dependency "mysql2"
  s.add_development_dependency "pg"
end
