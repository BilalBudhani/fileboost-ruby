require "openssl"
require "base64"

module Fileboost
  class SignatureGenerator
    def self.generate(asset_path:, params: {})
      # Sort parameters for consistent signature generation
      sorted_params = params.sort.to_h
      query_string = sorted_params.map { |k, v| "#{k}=#{v}" }.join("&")

      # Create the signing string: project_id:asset_path:sorted_query_params
      signing_string = [ Fileboost.config.project_id, asset_path, query_string ].join(":")
      # Generate HMAC-SHA256 signature for secure authentication with Fileboost.dev
      digest = OpenSSL::HMAC.digest("SHA256", Fileboost.config.token, signing_string)
      # Use URL-safe base64 encoding and remove padding for maximum URL compatibility
      Base64.urlsafe_encode64(digest, padding: false)
    end
  end
end
