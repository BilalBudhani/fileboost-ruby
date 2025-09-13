require "uri"

module Fileboost
  class UrlBuilder
    # Supported transformation parameters for Fileboost.dev service
    TRANSFORMATION_PARAMS = %w[
      w width
      h height
      q quality
      f format
      b blur
      br brightness
      c contrast
      r rotation
      fit
    ].freeze

    # Parameter aliases for convenience
    PARAM_ALIASES = {
      "width" => "w",
      "height" => "h",
      "quality" => "q",
      "format" => "f",
      "blur" => "b",
      "brightness" => "br",
      "contrast" => "c",
      "rotation" => "r"
    }.freeze

    # Valid resize parameter keys
    RESIZE_PARAMS = %w[w width h height q quality f format b blur br brightness c contrast r rotation fit].freeze

    def self.build_url(asset, **options)
      raise ConfigurationError, "Invalid configuration" unless Fileboost.config.valid?

      asset_path = extract_asset_path(asset)
      raise AssetPathExtractionError, "Unable to extract asset path" unless !asset_path.nil? && !asset_path.empty?

      project_id = Fileboost.config.project_id
      base_url = Fileboost.config.base_url

      # Build the full asset URL path for Fileboost.dev service
      full_path = "/#{project_id}#{asset_path}"

      # Extract and normalize transformation parameters
      transformation_params = extract_transformation_params(asset, options)

      # Generate HMAC signature for secure authentication
      signature = Fileboost::SignatureGenerator.generate(
        asset_path: asset_path,
        params: transformation_params
      )

      raise SignatureGenerationError, "Failed to generate signature" unless signature

      # Add signature to parameters
      all_params = transformation_params.merge("sig" => signature)

      # Build final URL
      uri = URI.join(base_url, full_path)
      uri.query = URI.encode_www_form(all_params) unless all_params.empty?

      uri.to_s
    end

    private

    def self.extract_asset_path(asset)
      case asset
      when ActiveStorage::Blob
        # ActiveStorage Blob
        Rails.application.routes.url_helpers.rails_blob_path(asset, only_path: true)

      when ActiveStorage::Attached
        # ActiveStorage Attachment (has_one_attached, has_many_attached)
        if asset.respond_to?(:blob) && !asset.blob.nil?
          Rails.application.routes.url_helpers.rails_blob_path(asset.blob, only_path: true)
        else
          raise AssetPathExtractionError, "ActiveStorage attachment has no blob"
        end

      when ActiveStorage::VariantWithRecord
        # ActiveStorage Variant - use blob URL to avoid triggering variant generation
        Rails.application.routes.url_helpers.rails_blob_path(asset.blob, only_path: true)

      else
        # Only ActiveStorage objects are supported
        raise AssetPathExtractionError, "Unsupported asset type: #{asset.class}. Only ActiveStorage objects are supported."
      end
    end

    def self.extract_transformation_params(asset, options)
      params = {}

      # First, extract variant transformations if this is a variant
      if asset.is_a?(ActiveStorage::VariantWithRecord)
        variant_params = Fileboost::VariantTransformer.transform_variant_params(asset)
        params.merge!(variant_params)
      end

      # Then handle explicit resize parameter (this can override variant params)
      if options[:resize].is_a?(Hash)
        resize_options = options[:resize]
        resize_options.each do |key, value|
          key_str = key.to_s

          # Only process valid resize parameters
          next unless RESIZE_PARAMS.include?(key_str)

          # Use alias if available
          param_key = PARAM_ALIASES[key_str] || key_str

          # Convert value to string and validate
          param_value = normalize_param_value(param_key, value)
          next if param_value.nil? || param_value.empty?

          params[param_key] = param_value
        end
      end

      params
    end

    def self.normalize_param_value(key, value)
      case key
      when "w", "h", "b", "br", "c", "r"
        # Numeric parameters
        value.to_i.to_s if value.to_i > 0
      when "q"
        # Quality parameter - validate range 1-100
        q = value.to_i
        (q > 0 && q <= 100) ? q.to_s : nil
      when "f"
        # Format parameter - validate against common formats
        valid_formats = %w[webp jpeg jpg png gif avif]
        normalized = value.to_s.downcase
        valid_formats.include?(normalized) ? normalized : nil
      when "fit"
        # Fit parameter - validate against supported values
        valid_fits = %w[cover contain fill scale-down crop pad]
        normalized = value.to_s.downcase.gsub("_", "-")
        valid_fits.include?(normalized) ? normalized : nil
      else
        value.to_s
      end
    end
  end
end
