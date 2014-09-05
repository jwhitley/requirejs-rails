require 'requirejs/rails'

require 'pathname'
require 'ostruct'

module Requirejs::Rails
  class Builder
    # config should be an instance of Requirejs::Rails::Config
    
    def initialize(config)
      @config = config
    end
    
    def build      
      @config.tmp_dir
    end

    def digest_for(path)
      if !Rails.application.assets.file_digest(path).nil?
        Rails.application.assets.file_digest(path).hexdigest
      else
        raise Requirejs::BuildError, "Cannot compute digest for missing asset: #{path}"
      end
    end

    def generate_rjs_driver
      templ = Erubis::Eruby.new(@config.driver_template_path.read)
      # Hack to allow functions in config by removing surrounding quotes
      driver = templ.result(@config.get_binding).gsub(/"(function\(.*?\)\s*?{.*?}[\s\\n]*)"/) do |f|
        eval(f).strip.delete("\n")
      end
      @config.driver_path.open('w') do |f|
        f.write(driver)
      end
    end
  end
end
