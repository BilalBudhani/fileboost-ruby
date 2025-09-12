require_relative "lib/fileboost/version"

Gem::Specification.new do |spec|
  spec.name        = "fileboost"
  spec.version     = Fileboost::VERSION
  spec.authors     = [ "bilal" ]
  spec.email       = [ "bilal@bilalbudhani.com" ]
  spec.homepage    = "https://github.com/bilalbudhani/fileboost-ruby"
  spec.summary     = "Rails gem for Fileboost.dev image optimization with ActiveStorage"
  spec.description = "Fileboost provides drop-in replacement Rails image helpers with automatic optimization through the Fileboost.dev service. Works exclusively with ActiveStorage objects, features HMAC authentication, and comprehensive transformation support."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/bilalbudhani/fileboost-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/bilalbudhani/fileboost-ruby/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.required_ruby_version = ">= 3.0"

  spec.add_runtime_dependency "activestorage", ">= 7.1"

  spec.add_development_dependency "appraisal", "~> 2.5"
  spec.add_development_dependency "bundler", "~> 2"
  spec.add_development_dependency "combustion", "~> 1"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rails", ">= 7.1"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-rails", "~> 6.0"
  spec.add_development_dependency "sqlite3", "~> 2.0"
end
