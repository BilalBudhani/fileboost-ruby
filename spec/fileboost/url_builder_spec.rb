require "spec_helper"

RSpec.describe Fileboost::UrlBuilder do
  let(:user) { User.create!(name: "Test User") }
  let(:blob) do
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("fake image data"),
      filename: "test.jpg",
      content_type: "image/jpeg"
    )
  end

  before do
    Fileboost.configure do |config|
      config.project_id = "test_project"
      config.token = "test_token"
    end
  end

  describe ".build_url" do
    context "with valid ActiveStorage::Blob" do
      it "builds a URL with signature" do
        url = Fileboost::UrlBuilder.build_url(blob, resize: { w: 300, h: 200 })

        expect(url).to include("https://cdn.fileboost.dev")
        expect(url).to include("test_project")
        expect(url).to include("sig=")
        expect(url).to include("w=300")
        expect(url).to include("h=200")
      end
    end

    context "with ActiveStorage attachment" do
      it "builds a URL for has_one_attached" do
        user.avatar.attach(blob)

        url = Fileboost::UrlBuilder.build_url(user.avatar, resize: { w: 300 })

        expect(url).to include("https://cdn.fileboost.dev")
        expect(url).to include("w=300")
        expect(url).to include("sig=")
      end
    end

    context "with invalid configuration" do
      it "raises ConfigurationError when config is invalid" do
        Fileboost.config.project_id = ""

        expect {
          Fileboost::UrlBuilder.build_url(blob)
        }.to raise_error(Fileboost::ConfigurationError)
      end
    end

    context "with unsupported asset type" do
      it "raises AssetPathExtractionError" do
        expect {
          Fileboost::UrlBuilder.build_url("invalid_asset")
        }.to raise_error(Fileboost::AssetPathExtractionError)
      end
    end
  end

  describe ".extract_transformation_params" do
    it "extracts and normalizes resize parameters" do
      options = { resize: { width: 300, height: 200, quality: 85, format: "webp" } }

      params = Fileboost::UrlBuilder.send(:extract_transformation_params, options)

      expect(params["w"]).to eq("300")
      expect(params["h"]).to eq("200")
      expect(params["q"]).to eq("85")
      expect(params["f"]).to eq("webp")
    end

    it "ignores invalid parameters" do
      options = { resize: { invalid_param: "value", w: 300 } }

      params = Fileboost::UrlBuilder.send(:extract_transformation_params, options)

      expect(params).not_to have_key("invalid_param")
      expect(params["w"]).to eq("300")
    end
  end

  describe ".normalize_param_value" do
    it "normalizes numeric parameters" do
      expect(Fileboost::UrlBuilder.send(:normalize_param_value, "w", 300)).to eq("300")
      expect(Fileboost::UrlBuilder.send(:normalize_param_value, "q", "85")).to eq("85")
      expect(Fileboost::UrlBuilder.send(:normalize_param_value, "w", 0)).to be_nil
    end

    it "validates format parameter" do
      expect(Fileboost::UrlBuilder.send(:normalize_param_value, "f", "webp")).to eq("webp")
      expect(Fileboost::UrlBuilder.send(:normalize_param_value, "f", "invalid")).to be_nil
    end

    it "validates fit parameter" do
      expect(Fileboost::UrlBuilder.send(:normalize_param_value, "fit", "cover")).to eq("cover")
      expect(Fileboost::UrlBuilder.send(:normalize_param_value, "fit", "scale_down")).to eq("scale-down")
      expect(Fileboost::UrlBuilder.send(:normalize_param_value, "fit", "invalid")).to be_nil
    end
  end
end
