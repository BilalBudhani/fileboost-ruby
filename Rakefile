require "bundler/setup"
require "bundler/gem_tasks"
require "rspec/core/rake_task"

begin
  require "appraisal"
rescue LoadError
  # Appraisal not available
end

RSpec::Core::RakeTask.new(:spec)

task default: :spec

namespace :test do
  desc "Run tests against all Rails versions"
  task :all do
    sh "bundle exec appraisal install"
    sh "bundle exec appraisal rspec"
  end

  desc "Run tests against specific Rails version (e.g. rake test:rails[7-1])"
  task :rails, [ :version ] do |t, args|
    version = args[:version] || "7-2"
    sh "bundle exec appraisal rails-#{version} rspec"
  end
end
