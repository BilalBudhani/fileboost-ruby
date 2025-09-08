require "openssl"
require "base64"

module Fileboost
  class SignatureGenerator
    def self.generate(project_id:, asset_path:, params: {})
      return nil unless project_id.present? && asset_path.present? && Fileboost.config.token.present?

      # Sort parameters for consistent signature generation
      sorted_params = params.sort.to_h
      query_string = sorted_params.map { |k, v| "#{k}=#{v}" }.join("&")

      # Create the signing string: project_id:asset_path:sorted_query_params
      signing_string = [project_id, asset_path, query_string].join(":")
      Rails.logger.debug("signature payload #{project_id}, #{asset_path}, #{query_string}, #{Fileboost.config.token}")
      # Generate HMAC-SHA256 signature for secure authentication with Fileboost.dev
      digest = OpenSSL::HMAC.digest("SHA256", Fileboost.config.token, signing_string)
      # Use URL-safe base64 encoding and remove padding for maximum URL compatibility
      Base64.urlsafe_encode64(digest, padding: false)
    rescue StandardError => e
      if defined?(Rails) && Rails.env.development?
        raise e
      else
        Rails.logger.warn("[Fileboost] Failed to generate signature: #{e.message}") if defined?(Rails)
        nil
      end
    end

    def self.verify_signature(project_id:, asset_path:, params: {}, signature:)
      expected_signature = generate(project_id: project_id, asset_path: asset_path, params: params)
      return false if expected_signature.nil? || signature.nil?

      # Use secure comparison to prevent timing attacks
      ActiveSupport::SecurityUtils.secure_compare(signature, expected_signature)
    rescue StandardError => e
      if defined?(Rails) && Rails.env.development?
        raise e
      else
        Rails.logger.warn("[Fileboost] Failed to verify signature: #{e.message}") if defined?(Rails)
        false
      end
    end
  end
end
