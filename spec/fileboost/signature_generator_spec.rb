require "spec_helper"

RSpec.describe Fileboost::SignatureGenerator do
  before do
    Fileboost.configure do |config|
      config.project_id = "test_project"
      config.token = "test_token"
    end
  end

  describe ".generate" do
    it "generates a signature for valid parameters" do
      signature = Fileboost::SignatureGenerator.generate(
        asset_path: "/test/path.jpg",
        params: { "w" => "300", "h" => "200" }
      )

      expect(signature).to be_a(String)
      expect(signature).not_to be_empty
    end

    it "generates consistent signatures for same inputs" do
      params = { "w" => "300", "h" => "200" }

      signature1 = Fileboost::SignatureGenerator.generate(
        asset_path: "/test/path.jpg",
        params: params
      )

      signature2 = Fileboost::SignatureGenerator.generate(
        asset_path: "/test/path.jpg",
        params: params
      )

      expect(signature1).to eq(signature2)
    end

    it "generates different signatures for different inputs" do
      signature1 = Fileboost::SignatureGenerator.generate(
        asset_path: "/test/path1.jpg",
        params: { "w" => "300" }
      )

      signature2 = Fileboost::SignatureGenerator.generate(
        asset_path: "/test/path2.jpg",
        params: { "w" => "300" }
      )

      expect(signature1).not_to eq(signature2)
    end

    it "parameter order does not affect signature" do
      signature1 = Fileboost::SignatureGenerator.generate(
        asset_path: "/test/path.jpg",
        params: { "w" => "300", "h" => "200" }
      )

      signature2 = Fileboost::SignatureGenerator.generate(
        asset_path: "/test/path.jpg",
        params: { "h" => "200", "w" => "300" }
      )

      expect(signature1).to eq(signature2)
    end
  end
end
