require "test_helper"

class SignatureGeneratorTest < ActiveSupport::TestCase
  def setup
    Fileboost.config.token = "test-secret-key"
  end

  test "generates consistent signatures for same inputs" do
    signature1 = Fileboost::SignatureGenerator.generate(
      project_id: "test-project",
      asset_path: "/test/image.jpg",
      params: { w: "400", h: "300" }
    )

    signature2 = Fileboost::SignatureGenerator.generate(
      project_id: "test-project",
      asset_path: "/test/image.jpg",
      params: { w: "400", h: "300" }
    )

    assert_equal signature1, signature2
    assert signature1.present?
  end

  test "generates different signatures for different inputs" do
    signature1 = Fileboost::SignatureGenerator.generate(
      project_id: "test-project",
      asset_path: "/test/image1.jpg",
      params: { w: "400", h: "300" }
    )

    signature2 = Fileboost::SignatureGenerator.generate(
      project_id: "test-project",
      asset_path: "/test/image2.jpg",
      params: { w: "400", h: "300" }
    )

    assert_not_equal signature1, signature2
  end

  test "parameter order does not affect signature" do
    signature1 = Fileboost::SignatureGenerator.generate(
      project_id: "test-project",
      asset_path: "/test/image.jpg",
      params: { w: "400", h: "300", q: "85" }
    )

    signature2 = Fileboost::SignatureGenerator.generate(
      project_id: "test-project",
      asset_path: "/test/image.jpg",
      params: { q: "85", h: "300", w: "400" }
    )

    assert_equal signature1, signature2
  end

  test "returns nil when token is missing" do
    Fileboost.config.token = nil

    signature = Fileboost::SignatureGenerator.generate(
      project_id: "test-project",
      asset_path: "/test/image.jpg",
      params: { w: "400" }
    )

    assert_nil signature
  end

  test "signature verification works correctly" do
    params = { w: "400", h: "300" }
    signature = Fileboost::SignatureGenerator.generate(
      project_id: "test-project",
      asset_path: "/test/image.jpg",
      params: params
    )

    assert Fileboost::SignatureGenerator.verify_signature(
      project_id: "test-project",
      asset_path: "/test/image.jpg",
      params: params,
      signature: signature
    )
  end

  test "signature verification fails with wrong signature" do
    params = { w: "400", h: "300" }

    assert_not Fileboost::SignatureGenerator.verify_signature(
      project_id: "test-project",
      asset_path: "/test/image.jpg",
      params: params,
      signature: "wrong-signature"
    )
  end
end