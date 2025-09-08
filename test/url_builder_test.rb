require "test_helper"

class UrlBuilderTest < ActiveSupport::TestCase
  def setup
    Fileboost.config.project_id = "test-project"
    Fileboost.config.token = "test-secret-key"
  end

  test "returns nil for non-ActiveStorage objects" do
    url = Fileboost::UrlBuilder.build_url("/test/image.jpg", width: 400, height: 300)
    assert_nil url

    url = Fileboost::UrlBuilder.build_url("image.jpg", width: 400)
    assert_nil url
  end

  test "returns nil when configuration is invalid" do
    Fileboost.config.project_id = nil
    
    url = Fileboost::UrlBuilder.build_url("any-object", width: 400)
    
    assert_nil url
  end
end