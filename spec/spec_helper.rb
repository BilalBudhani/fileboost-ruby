require "bundler/setup"

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require "combustion"

# Initialize Combustion with the components we need
Combustion.initialize! :active_storage, :action_controller, :action_view do
  config.load_defaults Rails::VERSION::STRING.to_f

  # Configure Active Storage for testing
  config.active_storage.variant_processor = :mini_magick
  config.active_storage.service = :test
end

require "rspec/rails"
require "fileboost"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on Module and main
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Include Rails test helpers
  config.include Rails.application.routes.url_helpers

  # Set up database before suite
  config.before(:suite) do
    Rails.logger.level = Logger::WARN unless ENV["VERBOSE"]

    # Ensure database tables are created
    ActiveRecord::Schema.verbose = false
    load Rails.root.join("db", "schema.rb")
  end

  # Clean up after each test
  config.around(:each) do |example|
    # Reset Fileboost configuration before each test
    Fileboost.instance_variable_set(:@config, nil)

    # Run test in a transaction that gets rolled back
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end
