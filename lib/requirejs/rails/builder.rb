require "ostruct"
require "pathname"

require "requirejs/rails"

module Requirejs
  module Rails
    class Builder
      def initialize(config)
        @config = config
      end

      def build
        @config.tmp_dir
      end

      def digest_for(path)
        if !::Rails.application.assets.file_digest(path).nil?
          ::Rails.application.assets.file_digest(path).hexdigest
        else
          raise Requirejs::BuildError, "Cannot compute digest for missing asset: #{path}"
        end
      end

      def generate_rjs_driver
        templ = Erubis::Eruby.new(@config.driver_template_path.read)
        @config.driver_path.open('w') do |f|
          f.write(templ.result(@config.get_binding))
        end
      end
    end
  end
end
