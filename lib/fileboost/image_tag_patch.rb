module Fileboost
  module ImageTagPatch
    def image_tag(source, options = {})
      # If this is an ActiveStorage asset and Fileboost is configured, use fileboost_image_tag
      if valid_activestorage_asset?(source) && Fileboost.config.valid?
        fileboost_image_tag(source, **options)
      else
        # Fall back to Rails' original image_tag for all other cases
        super(source, options)
      end
    rescue
      # If there's any error with Fileboost processing, fall back to original Rails behavior
      super(source, options)
    end

    private

    def valid_activestorage_asset?(asset)
      return true if asset.is_a?(ActiveStorage::Blob)
      return true if asset.is_a?(ActiveStorage::Attached)
      return true if asset.is_a?(ActiveStorage::VariantWithRecord)

      false
    end
  end
end
