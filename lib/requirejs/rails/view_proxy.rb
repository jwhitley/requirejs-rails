module Requirejs
  module Rails
    class ViewProxy
      include ActionView::Context
      include ActionView::Helpers::AssetUrlHelper
      include ActionView::Helpers::TagHelper
    end
  end
end
