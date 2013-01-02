require 'requirejs/rails/config'

require 'pathname'

module Requirejs
  module Rails
    class Engine < ::Rails::Engine

      ### Configuration setup
      config.before_configuration do
        config.requirejs = Requirejs::Rails::Config.new
        config.requirejs.precompile = [/require\.js$/]
      end

      config.before_initialize do |app|
        config = app.config

        # Process the user config file in #before_initalization (instead of #before_configuration) so that
        # environment-specific configuration can be injected into the user configuration file
        process_user_config_file(app, config)

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
          rjs_digests = YAML.load(ERB.new(File.new(config.requirejs.manifest_path).read).result)
          config.assets.digests.merge!(rjs_digests)
        end
      end

      private

      # Process the user-supplied config parameters, which will be
      # merged with the default params.  It should be a YAML file with
      # a single top-level hash, keys/values corresponding to require.js
      # config parameters.
      def process_user_config_file(app, config)
        config_path = Pathname.new(app.paths["config"].first)
        config.requirejs.user_config_file = config_path+'requirejs.yml'

        yaml_file_contents = nil
        if config.requirejs.user_config_file.exist?
          yaml_file_contents = config.requirejs.user_config_file.read
        else
          # if requirejs.yml doesn't exist, look for requirejs.yml.erb and process it as an erb
          config.requirejs.user_config_file = config_path+'requirejs.yml.erb'

          if config.requirejs.user_config_file.exist?
            yaml_file_contents = ERB.new(config.requirejs.user_config_file.read).result
          end
        end

        if yaml_file_contents.nil?
          # If we couldn't find any matching file contents to process, empty user config
          config.requirejs.user_config = {}
        else
          config.requirejs.user_config = YAML.load(yaml_file_contents)
        end
      end
    end # class Engine
  end
end
