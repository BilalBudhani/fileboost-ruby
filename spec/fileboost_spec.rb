require "spec_helper"

RSpec.describe Fileboost do
  it "has a version number" do
    expect(Fileboost::VERSION).not_to be nil
  end

  describe ".configure" do
    it "yields configuration object" do
      expect { |b| Fileboost.configure(&b) }.to yield_with_args(Fileboost::Config)
    end

    it "allows setting configuration values" do
      Fileboost.configure do |config|
        config.project_id = "new_project"
        config.token = "new_token"
      end

      expect(Fileboost.config.project_id).to eq("new_project")
      expect(Fileboost.config.token).to eq("new_token")
    end
  end

  describe ".config" do
    it "returns the same configuration instance" do
      config1 = Fileboost.config
      config2 = Fileboost.config

      expect(config1).to be(config2)
    end
  end
end
