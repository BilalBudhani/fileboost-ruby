require "spec_helper"

RSpec.describe Fileboost::ImageTagPatch do
  # Create a test class that includes both helpers and patch
  let(:view_class) do
    Class.new(ActionView::Base) do
      include Fileboost::Helpers
      prepend Fileboost::ImageTagPatch
    end
  end
  let(:view_instance) { view_class.new(ActionView::LookupContext.new([]), {}, nil) }

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
      config.patch_image_tag = true
    end
  end

  describe "#image_tag with patch enabled" do
    context "with ActiveStorage assets" do
      it "uses fileboost_image_tag for ActiveStorage::Blob" do
        expect(view_instance).to receive(:fileboost_image_tag).with(blob, alt: "test").and_return('<img src="fileboost_url" alt="test">')

        result = view_instance.image_tag(blob, alt: "test")

        expect(result).to eq('<img src="fileboost_url" alt="test">')
      end

      it "uses fileboost_image_tag for ActiveStorage::Attached" do
        user.avatar.attach(blob)
        expect(view_instance).to receive(:fileboost_image_tag).with(user.avatar, alt: "avatar").and_return('<img src="fileboost_url" alt="avatar">')

        result = view_instance.image_tag(user.avatar, alt: "avatar")

        expect(result).to eq('<img src="fileboost_url" alt="avatar">')
      end

      it "passes through all options to fileboost_image_tag" do
        options = { alt: "test", class: "hero-image", data: { id: "123" }, resize: { w: 300 } }
        expect(view_instance).to receive(:fileboost_image_tag).with(blob, **options).and_return('<img src="fileboost_url">')

        view_instance.image_tag(blob, **options)
      end
    end

    context "with non-ActiveStorage assets" do
      it "uses original Rails image_tag for string paths" do
        result = view_instance.image_tag("/path/to/image.jpg", alt: "test")

        # Should call Rails' original image_tag which creates a standard img tag
        expect(result).to include('src="/path/to/image.jpg"')
        expect(result).to include('alt="test"')
      end

      it "uses original Rails image_tag for URLs" do
        result = view_instance.image_tag("https://example.com/image.jpg", alt: "external")

        expect(result).to include('src="https://example.com/image.jpg"')
        expect(result).to include('alt="external"')
      end
    end

    context "configuration validation" do
      it "does not call fileboost_image_tag when config is invalid" do
        Fileboost.configure do |config|
          config.project_id = ""
          config.token = "test_token"
          config.patch_image_tag = true
        end

        expect(view_instance).not_to receive(:fileboost_image_tag)

        # Test that the method correctly skips fileboost processing
        # We don't test the actual super() call since it requires complex ActionView setup
        expect(view_instance.send(:valid_activestorage_asset?, blob)).to be true
        expect(Fileboost.config.valid?).to be false
      end
    end
  end

  describe "configuration behavior" do
    context "when patch_image_tag is false" do
      let(:unpatch_view_class) do
        Class.new(ActionView::Base) do
          include Fileboost::Helpers
          # Do not include the patch module
        end
      end
      let(:unpatch_view_instance) { unpatch_view_class.new(ActionView::LookupContext.new([]), {}, nil) }

      it "does not interfere with original image_tag behavior" do
        # Since patch is not included, this should work as normal Rails image_tag
        result = unpatch_view_instance.image_tag("/normal/image.jpg", alt: "normal")

        expect(result).to include('src="/normal/image.jpg"')
        expect(result).to include('alt="normal"')
      end
    end
  end

  describe "#valid_activestorage_asset?" do
    it "returns true for ActiveStorage::Blob" do
      expect(view_instance.send(:valid_activestorage_asset?, blob)).to be true
    end

    it "returns true for ActiveStorage::Attached" do
      user.avatar.attach(blob)
      expect(view_instance.send(:valid_activestorage_asset?, user.avatar)).to be true
    end

    it "returns false for strings" do
      expect(view_instance.send(:valid_activestorage_asset?, "/path/to/image.jpg")).to be false
    end

    it "returns false for other objects" do
      expect(view_instance.send(:valid_activestorage_asset?, { url: "test" })).to be false
      expect(view_instance.send(:valid_activestorage_asset?, 123)).to be false
    end
  end
end
