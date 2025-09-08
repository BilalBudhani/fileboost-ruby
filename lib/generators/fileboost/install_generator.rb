require "rails/generators/base"

module Fileboost
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc "Create Fileboost initializer file"
      
      def self.source_root
        @source_root ||= File.expand_path("templates", __dir__)
      end

      def create_initializer_file
        template "fileboost.rb", "config/initializers/fileboost.rb"
      end

      def show_readme
        readme "INSTALL" if behavior == :invoke
      end

      private

      def readme(path)
        say File.read(File.join(self.class.source_root, "#{path}.md"))
      end
    end
  end
end