require "test_helper"

class FileboostTest < ActiveSupport::TestCase
  def setup
    # Reset configuration for each test
    Fileboost.config.project_id = "test-project"
    Fileboost.config.token = "test-token"
  end

  test "it has a version number" do
    assert Fileboost::VERSION
  end

  test "configuration can be set via block" do
    Fileboost.configure do |config|
      config.project_id = "new-project"
      config.token = "new-token"
    end

    assert_equal "new-project", Fileboost.config.project_id
    assert_equal "new-token", Fileboost.config.token
  end

  test "configuration validates required fields" do
    Fileboost.config.project_id = nil
    assert_not Fileboost.config.valid?

    Fileboost.config.project_id = "test"
    Fileboost.config.token = nil
    assert_not Fileboost.config.valid?

    Fileboost.config.token = "test"
    assert Fileboost.config.valid?
  end

  test "base_url is hardcoded to cdn.fileboost.dev" do
    assert_equal "https://cdn.fileboost.dev", Fileboost.config.base_url
    assert_equal "cdn.fileboost.dev", Fileboost::Config::CDN_DOMAIN
  end
end
