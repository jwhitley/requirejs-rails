require 'requirejs/rails/config'

require 'pathname'

module Requirejs
  module Rails
    class Engine < ::Rails::Engine

      ### Configuration setup
      config.before_configuration do |app|
        config.requirejs = Requirejs::Rails::Config.new
        config.requirejs.precompile = [/require\.js$/]

        # Location of the user-supplied config parameters, which will be
        # merged with the default params.  It should be a YAML file with
        # a single top-level hash, keys/values corresponding to require.js
        # config parameters.
        config.requirejs.user_config_file = Pathname.new(app.paths["config"].first)+'requirejs.yml'
        if config.requirejs.user_config_file.exist?
          config.requirejs.user_config = YAML.load(config.requirejs.user_config_file.read)
        else
          config.requirejs.user_config = {}
        end
      end

      config.before_initialize do |app|
        config = app.config
        config.assets.precompile += config.requirejs.precompile

        manifest_path = File.join(::Rails.public_path, config.assets.prefix, "rjs_manifest.yml")
        config.requirejs.manifest_path = Pathname.new(manifest_path)
      end

      ### Initializers
      initializer "requirejs.tag_included_state" do |app|
        ActiveSupport.on_load(:action_controller) do
          ::ActionController::Base.class_eval do
            attr_accessor :requirejs_included
          end
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
