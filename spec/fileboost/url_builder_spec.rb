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

  let(:variant) do
    blob.variant(resize_to_limit: [ 300, 200 ])
  end

  before do
    Fileboost.configure do |config|
      config.project_id = "test_project"
      config.token = "test_token"
    end
  end

  after do
    blob.purge
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

    context "with ActiveStorage variant" do
      it "builds a URL with variant transformations" do
        variant = blob.variant(resize_to_limit: [ 100, 100 ])

        url = Fileboost::UrlBuilder.build_url(variant)

        expect(url).to include("https://cdn.fileboost.dev")
        expect(url).to include("w=100")
        expect(url).to include("h=100")
        expect(url).to include("fit=scale-down")
        expect(url).to include("sig=")
      end

      it "merges variant transformations with explicit resize options" do
        variant = blob.variant(resize_to_limit: [ 100, 100 ])

        url = Fileboost::UrlBuilder.build_url(variant, resize: { q: 85 })

        expect(url).to include("w=100")
        expect(url).to include("h=100")
        expect(url).to include("fit=scale-down")
        expect(url).to include("q=85")
      end

      it "allows explicit resize options to override variant parameters" do
        variant = blob.variant(resize_to_limit: [ 100, 100 ])

        url = Fileboost::UrlBuilder.build_url(variant, resize: { w: 200 })

        expect(url).to include("w=200") # overridden
        expect(url).to include("h=100") # from variant
        expect(url).to include("fit=scale-down") # from variant
      end

      it "builds a URL for named variants" do
        user.avatar.attach(blob)
        thumb_variant = user.avatar.variant(:thumb)

        url = Fileboost::UrlBuilder.build_url(thumb_variant)

        expect(url).to include("https://cdn.fileboost.dev")
        expect(url).to include("w=100")
        expect(url).to include("h=100")
        expect(url).to include("fit=scale-down")
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

    context "with parameter normalization" do
      it "normalizes resize parameters correctly" do
        url = Fileboost::UrlBuilder.build_url(blob, resize: { width: 300, height: 200, quality: 85, format: "webp" })

        expect(url).to include("w=300")
        expect(url).to include("h=200")
        expect(url).to include("q=85")
        expect(url).to include("f=webp")
      end

      it "ignores invalid parameters" do
        url = Fileboost::UrlBuilder.build_url(blob, resize: { invalid_param: "value", w: 300 })

        expect(url).to include("w=300")
        expect(url).not_to include("invalid_param")
      end

      it "rejects invalid quality values" do
        url = Fileboost::UrlBuilder.build_url(blob, resize: { q: 150 })

        expect(url).not_to include("q=150")
      end

      it "rejects invalid format values" do
        url = Fileboost::UrlBuilder.build_url(blob, resize: { f: "invalid" })

        expect(url).not_to include("f=invalid")
      end

      it "normalizes fit parameter correctly" do
        url = Fileboost::UrlBuilder.build_url(blob, resize: { fit: "scale_down" })

        expect(url).to include("fit=scale-down")
      end
    end
  end
end
