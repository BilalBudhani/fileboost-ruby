module Fileboost
  # Specific exception classes for better error handling
  class ConfigurationError < StandardError; end
  class SignatureGenerationError < StandardError; end
  class UrlBuildError < StandardError; end
  class AssetPathExtractionError < StandardError; end
end
