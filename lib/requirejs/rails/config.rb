require 'requirejs/rails'

require 'active_support/ordered_options'
require 'erubis'
require 'pathname'

module Requirejs::Rails
  class Config < ::ActiveSupport::OrderedOptions

    def initialize(app=Rails.application)
      super
      self.manifest = nil

      self.tmp_dir = Rails.root + 'tmp'
      self.bin_dir = Pathname.new(__FILE__+'/../../../../bin').cleanpath

      self.source_dir = self.tmp_dir + 'assets'
      self.target_dir = Rails.root + 'public/assets'
      self.rjs_path   = self.bin_dir+'r.js'

      self.driver_template_path = Pathname.new(__FILE__+'/../rjs_driver.js.erb').cleanpath
      self.driver_path = self.tmp_dir + 'rjs_driver.js'

      # The user-supplied config parameters, to be merged with the default params.
      # This file must contain a single JavaScript object.
      self.user_config_file = Pathname.new(app.paths["config"].first)+'requirejs.yml'
      if self.user_config_file.exist?
        self.user_config = YAML.load(self.user_config_file.read)
      else
        self.user_config = {}
      end

      self.run_config_whitelist = %w{
        baseUrl
        callback
        catchError
        context
        deps
        jQuery
        locale
        packages
        paths
        priority
        scriptType
        urlArgs
        waitSeconds
        xhtml
      }

      self.build_config_whitelist = %w{
        appDir
        baseUrl
        closure
        cssImportIgnore
        cssIn
        dir
        fileExclusionRegExp
        findNestedDependencies
        has
        hasOnSave
        include
        inlineText
        locale
        mainConfigFile
        modules
        name
        namespace
        onBuildRead
        onBuildWrite
        optimize
        optimizeAllPluginResources
        optimizeCss
        out
        packagePaths
        packages
        paths
        pragmas
        pragmasOnSave
        preserveLicenseComments
        skipModuleInsertion
        skipPragmas
        uglify
        useStrict
        wrap
      }
    end

    def build_config
      build_config = self.run_config.merge "baseUrl" => source_dir.to_s
      build_config.merge!(self.user_config).slice(*self.build_config_whitelist)
    end

    def run_config
      run_config = {
        "baseUrl" => "/assets",
        "modules" => [ { 'name' => 'application' } ]
      }
      run_config.merge!(self.user_config).slice(*self.run_config_whitelist)
    end

    def module_path_for(name)
      self.target_dir+(name+'.js')
    end

    def get_binding
      return binding()
    end
  end
end
