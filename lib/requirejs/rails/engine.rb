require 'requirejs/rails/config'

require 'pathname'

module Requirejs
  module Rails
    class Engine < ::Rails::Engine

      initializer "requirejs.config" do |app|
        config = app.config
        config.requirejs = Requirejs::Rails::Config.new(app)
        if config.requirejs.manifest
          path = File.join(config.assets.manifest, "rjs_manifest.yml")
        else
          path = File.join(::Rails.public_path, config.assets.prefix, "rjs_manifest.yml")
        end
        config.requirejs.manifest_path = Pathname.new(path)
        
        config.requirejs.precompile = [/require\.js$/]

        if ::Rails.env == "production"
          config.assets.precompile += config.requirejs.precompile
        end
      end
      
      initializer "requirejs.manifest", :after => "sprockets.environment" do |app|
        config = app.config
        if config.requirejs.manifest_path.exist? && config.assets.digests
          rjs_digests = YAML.load_file(config.requirejs.manifest_path)
          config.assets.digests.merge!(rjs_digests)
        end
      end
      
    end # class Engine
  end
end
