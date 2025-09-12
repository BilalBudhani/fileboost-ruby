require "spec_helper"

RSpec.describe Fileboost::Helpers do
  include Fileboost::Helpers

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

  describe "#fileboost_url_for" do
    it "generates URL for ActiveStorage::Blob" do
      url = fileboost_url_for(blob, resize: { w: 300 })

      expect(url).to include("https://cdn.fileboost.dev")
      expect(url).to include("w=300")
      expect(url).to include("sig=")
    end

    it "generates URL for ActiveStorage attachment" do
      user.avatar.attach(blob)

      url = fileboost_url_for(user.avatar, resize: { w: 300 })

      expect(url).to include("https://cdn.fileboost.dev")
      expect(url).to include("w=300")
    end

    it "generates URL for ActiveStorage variant" do
      variant = blob.variant(resize_to_limit: [ 100, 100 ])

      url = fileboost_url_for(variant)

      expect(url).to include("https://cdn.fileboost.dev")
      expect(url).to include("w=100")
      expect(url).to include("h=100")
      expect(url).to include("fit=scale-down")
    end

    it "generates URL for named variants" do
      user.avatar.attach(blob)
      thumb_variant = user.avatar.variant(:thumb)

      url = fileboost_url_for(thumb_variant)

      expect(url).to include("https://cdn.fileboost.dev")
      expect(url).to include("w=100")
      expect(url).to include("h=100")
      expect(url).to include("fit=scale-down")
    end

    it "raises ArgumentError for invalid asset type" do
      expect {
        fileboost_url_for("invalid", resize: { w: 300 })
      }.to raise_error(ArgumentError, /Invalid asset type/)
    end

    it "raises ConfigurationError for invalid configuration" do
      Fileboost.config.project_id = ""

      expect {
        fileboost_url_for(blob)
      }.to raise_error(Fileboost::ConfigurationError)
    end
  end

  describe "#fileboost_image_tag" do
    it "generates image tag with optimized URL" do
      allow(self).to receive(:image_tag).and_return('<img src="optimized_url" alt="test">')

      result = fileboost_image_tag(blob, resize: { w: 300 }, alt: "test")

      expect(result).to eq('<img src="optimized_url" alt="test">')
    end

    it "generates image tag for variants" do
      variant = blob.variant(resize_to_limit: [ 100, 100 ])
      allow(self).to receive(:image_tag).and_return('<img src="variant_url" alt="test">')

      result = fileboost_image_tag(variant, alt: "test")

      expect(result).to eq('<img src="variant_url" alt="test">')
    end

    it "generates image tag for named variants" do
      user.avatar.attach(blob)
      thumb_variant = user.avatar.variant(:thumb)
      allow(self).to receive(:image_tag).and_return('<img src="thumb_url" alt="test">')

      result = fileboost_image_tag(thumb_variant, alt: "test")

      expect(result).to eq('<img src="thumb_url" alt="test">')
    end
  end

  describe "#fileboost_responsive_urls" do
    it "generates multiple URLs for responsive images" do
      sizes = [
        { width: 400, suffix: "sm" },
        { width: 800, suffix: "md" },
        { width: 1200, suffix: "lg" }
      ]

      urls = fileboost_responsive_urls(blob, sizes, resize: { quality: 85 })

      expect(urls).to have_key("sm")
      expect(urls).to have_key("md")
      expect(urls).to have_key("lg")
      expect(urls["sm"]).to include("w=400")
      expect(urls["md"]).to include("w=800")
      expect(urls["lg"]).to include("w=1200")
    end
  end

  describe "#valid_activestorage_asset?" do
    it "returns true for ActiveStorage::Blob" do
      expect(send(:valid_activestorage_asset?, blob)).to be true
    end

    it "returns true for ActiveStorage::Attached" do
      user.avatar.attach(blob)
      expect(send(:valid_activestorage_asset?, user.avatar)).to be true
    end

    it "returns false for invalid asset types" do
      expect(send(:valid_activestorage_asset?, "string")).to be false
      expect(send(:valid_activestorage_asset?, 123)).to be false
    end
  end
end
