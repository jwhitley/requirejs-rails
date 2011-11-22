require 'test_helper'

require 'execjs'
require 'pathname'

class RequirejsRailsTest < ActiveSupport::TestCase
  test "truth" do
    assert_kind_of Module, Requirejs
    assert_kind_of Module, Requirejs::Rails
  end
  
  test "require.js version" do
    require_js = Pathname.new(__FILE__+'/../../vendor/assets/javascripts/require.js').cleanpath.read
    context = ExecJS.compile(require_js)
    assert_equal "1.0.2", context.eval("require.version")
  end
end
