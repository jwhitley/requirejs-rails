require 'requirejs/rails'

require 'erubis'
require 'pathname'

module Requirejs::Rails
  class Config
    def run_config
      unless @run_config
        @run_config = {
          "baseUrl" => "/assets",
          "modules" => [ { name: 'application' } ]
        }
        @run_config.merge!(self.user_config)
      end
      @run_config
    end
    
    def run_config_json
      @run_config_json ||= self.run_config.to_json
    end
    
    def build_config
      unless @build_config
        @build_config = self.run_config.merge "baseUrl" => source_dir.to_s
        @build_config.merge!(self.user_config)
      end
      @build_config
    end
    
    def user_config
      if self.user_config_file.exist?
        @user_config = YAML.load(self.user_config_file.read)
      end
      @user_config ||= {}
    end
    
    def user_config_file
      # The user-supplied config parameters, to be merged with the default params.
      # This file must contain a single JavaScript object.
      @user_config_file ||= Pathname.new(Rails.application.paths.config.first)+'requirejs.yml'
    end
    
    def source_dir
      @source_dir ||= self.tmp_dir + 'assets'
    end
    
    def target_dir
      @target_dir ||= Rails.root + 'public/assets'
    end
    
    def bin_dir
      @bin_dir ||= Pathname.new(__FILE__+'/../../../../bin').cleanpath
    end
    
    def rjs_path
      @rjs_path ||= self.bin_dir+'r.js'
    end
    
    def driver_template_path
      @driver_template_path ||= Pathname.new(__FILE__+'/../rjs_driver.js.erb').cleanpath
    end
    
    def driver_path
      @driver_path ||= self.tmp_dir + 'rjs_driver.js'
    end
    
    def tmp_dir
      @tmp_dir ||= Rails.root + 'tmp'
    end
    
    def module_path_for(name)
      self.target_dir+(name+'.js')
    end
    
    def get_binding
      return binding()
    end    
  end
end