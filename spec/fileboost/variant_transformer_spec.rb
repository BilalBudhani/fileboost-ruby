require "spec_helper"

RSpec.describe Fileboost::VariantTransformer do
  let(:user) { User.create!(name: "Test User") }
  let(:blob) do
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("fake image data"),
      filename: "test.jpg",
      content_type: "image/jpeg"
    )
  end

  after do
    blob.purge
  end

  describe ".transform_variant_params" do
    context "with resize_to_limit" do
      it "transforms resize_to_limit to w, h, and fit=scale-down" do
        variant = blob.variant(resize_to_limit: [ 100, 100 ])
        params = described_class.transform_variant_params(variant)

        expect(params["w"]).to eq("100")
        expect(params["h"]).to eq("100")
        expect(params["fit"]).to eq("scale-down")
      end
    end

    context "with resize_to_fit" do
      it "transforms resize_to_fit to w, h, and fit=contain" do
        variant = blob.variant(resize_to_fit: [ 200, 150 ])
        params = described_class.transform_variant_params(variant)

        expect(params["w"]).to eq("200")
        expect(params["h"]).to eq("150")
        expect(params["fit"]).to eq("contain")
      end
    end

    context "with resize_to_fill" do
      it "transforms resize_to_fill to w, h, and fit=cover" do
        variant = blob.variant(resize_to_fill: [ 300, 200 ])
        params = described_class.transform_variant_params(variant)

        expect(params["w"]).to eq("300")
        expect(params["h"]).to eq("200")
        expect(params["fit"]).to eq("cover")
      end
    end

    context "with quality" do
      it "transforms quality to q parameter" do
        variant = blob.variant(quality: 85)
        params = described_class.transform_variant_params(variant)

        expect(params["q"]).to eq("85")
      end

      it "rejects invalid quality values" do
        variant = blob.variant(quality: 150)
        params = described_class.transform_variant_params(variant)

        expect(params["q"]).to be_nil
      end
    end

    context "with format" do
      it "transforms format to f parameter" do
        variant = blob.variant(format: :webp)
        params = described_class.transform_variant_params(variant)

        expect(params["f"]).to eq("webp")
      end

      it "normalizes jpeg to jpg" do
        variant = blob.variant(format: :jpeg)
        params = described_class.transform_variant_params(variant)

        expect(params["f"]).to eq("jpg")
      end
    end

    context "with rotation" do
      it "transforms rotate parameter" do
        variant = blob.variant(rotate: "-90")
        params = described_class.transform_variant_params(variant)

        expect(params["r"]).to eq("-90")
      end
    end

    context "with multiple transformations" do
      it "transforms multiple parameters correctly" do
        variant = blob.variant(
          resize_to_limit: [ 400, 300 ],
          quality: 90,
          format: :webp
        )
        params = described_class.transform_variant_params(variant)

        expect(params["w"]).to eq("400")
        expect(params["h"]).to eq("300")
        expect(params["fit"]).to eq("scale-down")
        expect(params["q"]).to eq("90")
        expect(params["f"]).to eq("webp")
      end
    end

    context "with named variants" do
      it "transforms named variant (:thumb) correctly" do
        user.avatar.attach(blob)
        thumb_variant = user.avatar.variant(:thumb)
        params = described_class.transform_variant_params(thumb_variant)

        # Based on user.rb: attachable.variant :thumb, resize_to_limit: [100, 100]
        expect(params["w"]).to eq("100")
        expect(params["h"]).to eq("100")
        expect(params["fit"]).to eq("scale-down")
      end
    end

    context "with non-variant objects" do
      it "returns empty hash for blobs" do
        params = described_class.transform_variant_params(blob)
        expect(params).to eq({})
      end

      it "returns empty hash for strings" do
        params = described_class.transform_variant_params("not_a_variant")
        expect(params).to eq({})
      end
    end
  end

    context "with edge cases and validation" do
      it "handles invalid quality values by excluding them" do
        variant = blob.variant(quality: 0)
        params = described_class.transform_variant_params(variant)

        expect(params["q"]).to be_nil
      end

      it "handles negative quality values by excluding them" do
        variant = blob.variant(quality: -10)
        params = described_class.transform_variant_params(variant)

        expect(params["q"]).to be_nil
      end

      it "handles quality values over 100 by excluding them" do
        variant = blob.variant(quality: 150)
        params = described_class.transform_variant_params(variant)

        expect(params["q"]).to be_nil
      end

      it "normalizes JPEG format to jpg" do
        variant = blob.variant(format: "JPEG")
        params = described_class.transform_variant_params(variant)

        expect(params["f"]).to eq("jpg")
      end

      it "handles invalid format values by excluding them" do
        variant = blob.variant(format: "invalid")
        params = described_class.transform_variant_params(variant)

        expect(params["f"]).to be_nil
      end

      it "handles unknown format values by excluding them" do
        variant = blob.variant(format: "unknown")
        params = described_class.transform_variant_params(variant)

        expect(params["f"]).to be_nil
      end

      it "normalizes rotation with degrees suffix" do
        variant = blob.variant(rotate: "-90deg")
        params = described_class.transform_variant_params(variant)

        expect(params["r"]).to eq("-90")
      end

      it "normalizes rotation with function syntax" do
        variant = blob.variant(rotate: "rotate(180)")
        params = described_class.transform_variant_params(variant)

        expect(params["r"]).to eq("180")
      end

      it "handles numeric rotation values" do
        variant = blob.variant(rotate: -90)
        params = described_class.transform_variant_params(variant)

        expect(params["r"]).to eq("-90")
      end
    end
end
