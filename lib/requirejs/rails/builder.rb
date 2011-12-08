require 'requirejs/rails'

require 'pathname'
require 'ostruct'

module Requirejs::Rails
  # An instance of this class provides the context for generation of 
  # the r.js builder script.  See also: lib/tasks/builder.js.erb
  # in this project.
  class Builder
    def initialize(config)
      @config = config
    end
    
    def build      
      @config.tmp_dir
    end

    def generate_rjs_driver
      templ = Erubis::Eruby.new(@config.driver_template_path.read)
      @config.driver_path.open('w') do |f|
        f.write(templ.result(@config.get_binding))
      end
    end
  end
end