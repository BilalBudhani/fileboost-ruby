module Fileboost
  class Engine < ::Rails::Engine
    isolate_namespace Fileboost

    initializer "fileboost.action_view" do
      ActiveSupport.on_load :action_view do
        include Fileboost::Helpers
      end
    end
  end
end
