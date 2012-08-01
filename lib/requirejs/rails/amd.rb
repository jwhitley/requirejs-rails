require 'sprockets'
require 'tilt'

module Requirejs
  module Rails
    class AMD < Tilt::Template
      def prepare
      end

      def evaluate(context, locals, &block)
        if should_wrap?(context)
          ::Rails.application.config.requirejs.amd_wrap_template % [ data ]
        else
          data
        end
      end

      def should_wrap?(context)
        filter = ::Rails.application.config.requirejs.amd_wrap_filter
        filter && filter.any?{|re| re =~ context.pathname.to_s}
      end
    end
  end
end
