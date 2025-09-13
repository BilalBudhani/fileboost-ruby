require "spec_helper"

RSpec.describe Fileboost::Config do
  describe "#initialize" do
    it "loads configuration from environment variables" do
      ENV["FILEBOOST_PROJECT_ID"] = "test_project"
      ENV["FILEBOOST_TOKEN"] = "test_token"

      config = Fileboost::Config.new

      expect(config.project_id).to eq("test_project")
      expect(config.token).to eq("test_token")
      expect(config.patch_image_tag).to eq(false)

      ENV.delete("FILEBOOST_PROJECT_ID")
      ENV.delete("FILEBOOST_TOKEN")
    end

    it "sets patch_image_tag to false by default" do
      config = Fileboost::Config.new

      expect(config.patch_image_tag).to eq(false)
    end
  end

  describe "#valid?" do
    it "returns true when both project_id and token are present" do
      config = Fileboost::Config.new
      config.project_id = "test_project"
      config.token = "test_token"

      expect(config).to be_valid
    end

    it "returns false when project_id is missing" do
      config = Fileboost::Config.new
      config.project_id = ""
      config.token = "test_token"

      expect(config).not_to be_valid
    end

    it "returns false when token is missing" do
      config = Fileboost::Config.new
      config.project_id = "test_project"
      config.token = ""

      expect(config).not_to be_valid
    end
  end

  describe "#base_url" do
    it "returns the hardcoded CDN domain" do
      config = Fileboost::Config.new
      expect(config.base_url).to eq("https://cdn.fileboost.dev")
    end
  end
end
