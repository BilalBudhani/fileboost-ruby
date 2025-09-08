module Fileboost
  class ErrorHandler
    class << self
      def handle_with_fallback(error_context, &block)
        begin
          yield
        rescue StandardError => e
          log_error(error_context, e)
          
          if Fileboost.config.fallback_to_rails
            yield_fallback if block_given?
          else
            nil
          end
        end
      end

      def handle_gracefully(error_context, default_value = nil, &block)
        begin
          yield
        rescue StandardError => e
          log_error(error_context, e)
          default_value
        end
      end

      private

      def log_error(context, error)
        return unless defined?(Rails) && Rails.logger

        Rails.logger.warn(
          "[Fileboost] Error in #{context}: #{error.class}: #{error.message}"
        )
        
        # Log backtrace in development for debugging
        if Rails.env.development?
          Rails.logger.debug(
            "[Fileboost] Backtrace:\n#{error.backtrace.take(5).join("\n")}"
          )
        end
      end

      def yield_fallback
        # This would be implemented by the calling code
        # The pattern is to pass a fallback block when needed
        nil
      end
    end
  end

  # Specific exception classes for better error handling
  class ConfigurationError < StandardError; end
  class SignatureGenerationError < StandardError; end
  class UrlBuildError < StandardError; end
  class AssetPathExtractionError < StandardError; end
end