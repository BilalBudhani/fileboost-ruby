module Fileboost
  class Engine < ::Rails::Engine
    isolate_namespace Fileboost

    initializer "fileboost.action_view" do
      ActiveSupport.on_load :action_view do
        include Fileboost::Helpers
      end
    end

    initializer "fileboost.active_storage" do
      ActiveSupport.on_load :active_storage_blob do
        # Extend ActiveStorage::Blob with fileboost-specific methods if needed
      end
    end
  end
end
