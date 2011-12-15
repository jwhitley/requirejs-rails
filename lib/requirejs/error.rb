module Requirejs
  # Raised if requirejs_include_tag appears multiple times on a page.
  class MultipleIncludeError < RuntimeError; end
end