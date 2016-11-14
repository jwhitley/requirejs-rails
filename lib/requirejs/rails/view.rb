module Requirejs
  module Rails
    class View < ::ActionView::Base
      # This allows requirejs-rails to serve up modules by their undigestified asset paths.
      self.check_precompiled_asset = false \
        if respond_to?(:check_precompiled_asset)
    end
  end
end
