module Fileboost
  class Config
    attr_accessor :project_id, :token, :patch_image_tag

    CDN_DOMAIN = "cdn.fileboost.dev"
    BASE_URL = "https://#{CDN_DOMAIN}"

    def initialize
      @project_id = ENV["FILEBOOST_PROJECT_ID"]
      @token = ENV["FILEBOOST_TOKEN"]
      @patch_image_tag = false
    end

    def valid?
      !project_id.empty? && !token.empty?
    end

    def base_url
      BASE_URL
    end
  end

  def self.config
    @config ||= Config.new
  end

  def self.configure
    yield(config) if block_given?
  end
end
