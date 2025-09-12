module Fileboost
  class Engine < ::Rails::Engine
    isolate_namespace Fileboost

    initializer "fileboost.action_view" do
      ActiveSupport.on_load :action_view do
        include Fileboost::Helpers

        # Conditionally patch image_tag if enabled in configuration
        if Fileboost.config.patch_image_tag
          prepend Fileboost::ImageTagPatch
        end
      end
    end
  end
end
