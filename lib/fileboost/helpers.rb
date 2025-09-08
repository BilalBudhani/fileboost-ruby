require "active_storage"

module Fileboost
  module Helpers
    # Generate an optimized image tag using Fileboost
    #
    # @param asset [ActiveStorage::Blob, ActiveStorage::Attached, ActiveStorage::VariantWithRecord] The ActiveStorage image asset
    # @param options [Hash] Image transformation and HTML options
    # @return [String] HTML image tag
    #
    # Examples:
    #   fileboost_image_tag(user.avatar, resize: { w: 300, h: 200 }, alt: "Avatar")
    #   fileboost_image_tag(post.featured_image.blob, resize: { width: 1200, quality: 90 }, class: "hero-image")
    def fileboost_image_tag(asset, **options)
      # Extract resize options for transformation
      resize_options = options.delete(:resize) || {}

      # Generate the optimized URL
      optimized_url = fileboost_url_for(asset, resize: resize_options)

      # Return empty string if no URL could be generated
      return "" if optimized_url.blank?

      # Use the optimized URL with Rails image_tag for consistency
      image_tag(optimized_url, **options)
    end

    # Generate an optimized URL using Fileboost
    #
    # @param asset [ActiveStorage::Blob, ActiveStorage::Attached, ActiveStorage::VariantWithRecord] The ActiveStorage image asset
    # @param options [Hash] Image transformation options
    # @return [String, nil] The optimized URL or nil if generation failed
    #
    # Examples:
    #   fileboost_url_for(post.image, resize: { width: 500, format: :webp })
    #   fileboost_url_for(user.avatar.blob, resize: { w: 1200, h: 400, q: 85 })
    def fileboost_url_for(asset, **options)
      # Validate that asset is an ActiveStorage object
      unless valid_activestorage_asset?(asset)
        Rails.logger.error("[Fileboost] Invalid asset type #{asset.class}. Only ActiveStorage objects are supported.") if defined?(Rails)
        return nil
      end

      # Validate configuration
      unless Fileboost.config.valid?
        log_configuration_warning
        return nil
      end

      # Build the optimized URL
      Fileboost::UrlBuilder.build_url(asset, **options)
    end

    # Generate multiple image URLs for responsive images
    #
    # @param asset [ActiveStorage::Blob, ActiveStorage::Attached, ActiveStorage::VariantWithRecord] The ActiveStorage image asset
    # @param sizes [Array<Hash>] Array of size configurations
    # @param base_options [Hash] Base transformation options applied to all sizes
    # @return [Hash] Hash with size keys and URL values
    #
    # Example:
    #   fileboost_responsive_urls(hero.image, [
    #     { width: 400, suffix: "sm" },
    #     { width: 800, suffix: "md" },
    #     { width: 1200, suffix: "lg" }
    #   ], resize: { quality: 85, format: :webp })
    #   # Returns: { "sm" => "url1", "md" => "url2", "lg" => "url3" }
    def fileboost_responsive_urls(asset, sizes, **base_options)
      urls = {}

      sizes.each do |size_config|
        suffix = size_config[:suffix] || size_config["suffix"]
        size_options = size_config.except(:suffix, "suffix")
        combined_options = base_options.merge(size_options)

        url = fileboost_url_for(asset, **combined_options)
        urls[suffix] = url if url.present?
      end

      urls
    end

    private


    # Validate that the asset is a supported ActiveStorage object
    def valid_activestorage_asset?(asset)
      return true if asset.is_a?(ActiveStorage::Blob)
      return true if asset.is_a?(ActiveStorage::Attached)
      return true if asset.is_a?(ActiveStorage::VariantWithRecord)

      false
    end

    # Log configuration warnings
    def log_configuration_warning
      missing_configs = []
      missing_configs << "project_id" if Fileboost.config.project_id.blank?
      missing_configs << "token" if Fileboost.config.token.blank?

      Rails.logger.warn(
        "[Fileboost] Configuration incomplete. Missing: #{missing_configs.join(', ')}. " \
        "Set FILEBOOST_PROJECT_ID and FILEBOOST_TOKEN environment variables or configure them in your initializer."
      ) if defined?(Rails)
    end
  end
end
