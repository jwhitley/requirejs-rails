require 'requirejs/rails/config'

module Requirejs
  module Rails
    class Engine < ::Rails::Engine
      config.requirejs = Requirejs::Rails::Config.new
    end
  end
end
