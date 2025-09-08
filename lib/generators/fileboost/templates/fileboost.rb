# Fileboost Configuration
#
# Configure your Fileboost integration for seamless image optimization
# through the Fileboost.dev service. Set up your environment variables or
# configure the values directly below.
#
# Fileboost uses cdn.fileboost.dev as the CDN domain and only supports
# ActiveStorage objects.

Fileboost.configure do |config|
  # Your unique Fileboost project identifier
  # You can also set this via the FILEBOOST_PROJECT_ID environment variable
  config.project_id = ENV["FILEBOOST_PROJECT_ID"] # || "your-project-id"

  # HMAC signing secret for secure authentication with Fileboost.dev service
  # You can also set this via the FILEBOOST_TOKEN environment variable
  # IMPORTANT: Keep this secret secure and never commit it to version control
  config.token = ENV["FILEBOOST_TOKEN"] # || "your-secret-token"
end
