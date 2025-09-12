module Fileboost
  # Maps ActiveStorage variant transformations to Fileboost URL parameters
  class VariantTransformer
    # Maps ActiveStorage transformation operations to Fileboost parameters
    TRANSFORMATION_MAPPING = {
      # Resize operations
      resize_to_limit: { fit: "scale-down" },
      resize_to_fit: { fit: "contain" },
      resize_to_fill: { fit: "cover" },
      resize_and_pad: { fit: "pad" },

      # Quality settings
      quality: { param: "q" },

      # Format settings
      format: { param: "f" },

      # Rotation
      rotate: { param: "r" },

      # Crop operations - need special handling
      crop: { special: :crop_handler }
    }.freeze

    # Convert ActiveStorage variant transformations to Fileboost parameters
    def self.transform_variant_params(variant)
      return {} unless variant.respond_to?(:variation)

      transformations = variant.variation.transformations
      params = {}

      transformations.each do |operation, value|
        case operation
        when :resize_to_limit, :resize_to_fit, :resize_to_fill, :resize_and_pad
          resize_params = handle_resize_operation(operation, value)
          params.merge!(resize_params)

        when :quality
          params["q"] = normalize_quality(value)

        when :format
          params["f"] = normalize_format(value)

        when :rotate
          params["r"] = normalize_rotation(value)

        when :crop
          crop_params = handle_crop_operation(value)
          params.merge!(crop_params) if crop_params

          # Add more transformations as needed
        end
      end

      params
    end

    private

    # Handle resize operations (resize_to_limit, resize_to_fit, etc.)
    def self.handle_resize_operation(operation, dimensions)
      return {} unless dimensions.is_a?(Array) && dimensions.length >= 2

      width, height = dimensions[0], dimensions[1]
      params = {}

      # Set dimensions
      params["w"] = width.to_s if width && width > 0
      params["h"] = height.to_s if height && height > 0

      # Set fit parameter based on resize operation
      fit_mapping = TRANSFORMATION_MAPPING[operation]
      params["fit"] = fit_mapping[:fit] if fit_mapping && fit_mapping[:fit]

      params
    end

    # Handle crop operations
    def self.handle_crop_operation(crop_params)
      # Crop can be in different formats depending on the processor
      # For now, we'll handle simple array format: [x, y, width, height]
      if crop_params.is_a?(Array) && crop_params.length == 4
        x, y, w, h = crop_params
        return { "crop" => "#{x},#{y},#{w},#{h}" }
      end

      # Could extend this for other crop formats
      nil
    end

    # Normalize quality value (0-100)
    def self.normalize_quality(quality)
      q = quality.to_i
      return nil if q <= 0 || q > 100
      q.to_s
    end

    # Normalize format value
    def self.normalize_format(format)
      # Convert to string and lowercase
      format_str = format.to_s.downcase

      # Map common format variations
      case format_str
      when "jpg", "jpeg"
        "jpg"
      when "png"
        "png"
      when "webp"
        "webp"
      when "avif"
        "avif"
      when "gif"
        "gif"
      else
        # If it's already a recognized format, use it
        valid_formats = %w[webp jpeg jpg png gif avif]
        valid_formats.include?(format_str) ? format_str : nil
      end
    end

    # Normalize rotation value
    def self.normalize_rotation(rotation)
      # Rotation should be a number (degrees)
      r = rotation.to_s.gsub(/[^\d\-]/, "") # Remove non-numeric chars except minus
      return nil if r.empty?
      r
    end
  end
end
