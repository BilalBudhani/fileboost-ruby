require "test_helper"

class ResizeParameterTest < ActiveSupport::TestCase
  def setup
    Fileboost.config.project_id = "test-project"
    Fileboost.config.token = "test-secret-key"
  end

  test "extract_transformation_params handles resize parameter" do
    options = {
      resize: {
        width: 400,
        height: 300,
        quality: 85,
        format: :webp
      },
      class: "hero-image"
    }

    params = Fileboost::UrlBuilder.send(:extract_transformation_params, options)

    assert_equal "400", params["w"]
    assert_equal "300", params["h"] 
    assert_equal "85", params["q"]
    assert_equal "webp", params["f"]
    assert_nil params["class"] # Should not be included in transformation params
  end

  test "extract_transformation_params handles short parameter names in resize" do
    options = {
      resize: {
        w: 400,
        h: 300,
        q: 85,
        f: :webp
      }
    }

    params = Fileboost::UrlBuilder.send(:extract_transformation_params, options)

    assert_equal "400", params["w"]
    assert_equal "300", params["h"]
    assert_equal "85", params["q"] 
    assert_equal "webp", params["f"]
  end

  test "extract_transformation_params ignores direct parameters without resize" do
    options = {
      width: 500,
      height: 400,
      quality: 90
    }

    params = Fileboost::UrlBuilder.send(:extract_transformation_params, options)

    # Should be empty since no resize parameter
    assert_empty params
  end

  test "extract_transformation_params ignores invalid resize parameters" do
    options = {
      resize: {
        width: 400,
        invalid_param: "ignored",
        height: 300
      }
    }

    params = Fileboost::UrlBuilder.send(:extract_transformation_params, options)

    assert_equal "400", params["w"]
    assert_equal "300", params["h"]
    assert_nil params["invalid_param"]
  end

  test "extract_transformation_params handles empty resize parameter" do
    options = {
      resize: {},
      width: 400  # Should be ignored
    }

    params = Fileboost::UrlBuilder.send(:extract_transformation_params, options)

    # Should be empty since resize parameter is empty hash
    assert_empty params
  end

  test "extract_transformation_params handles non-hash resize parameter" do
    options = {
      resize: "invalid",
      width: 400
    }

    params = Fileboost::UrlBuilder.send(:extract_transformation_params, options)

    # Should be empty since resize parameter is not a hash
    assert_empty params
  end
end