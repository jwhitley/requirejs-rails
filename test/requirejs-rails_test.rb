require 'test_helper'

require 'execjs'
require 'pathname'

class RequirejsRailsTest < ActiveSupport::TestCase
  test "truth" do
    assert_kind_of Module, Requirejs
    assert_kind_of Module, Requirejs::Rails
    assert_kind_of Class, Requirejs::Rails::Engine
  end
  
  test "require.js version" do
    require_js = Pathname.new(__FILE__+'/../../vendor/assets/javascripts/require.js').cleanpath.read
    context = ExecJS.compile(require_js)
    assert_equal "1.0.5", context.eval("require.version")
  end
end

class RequirejsHelperTest < ActionView::TestCase
  
  def setup
    controller.requirejs_included = false
  end
  
  def wrap(tag)
    "<html><head>#{tag}</head></html>"
  end
  
  test "requirejs_include_tag" do
    render :text => wrap(requirejs_include_tag)
    assert_select "script:first-of-type", :text => /var require =/
    assert_select "script:last-of-type[src^=/javascripts/require.js]", :count => 1
  end
  
  test "requirejs_include_tag_with_param" do
    render :text => wrap(requirejs_include_tag("application"))
    assert_select "script:last-of-type[src^=/javascripts/require.js][data-main^=/javascripts/application.js]", :count => 1
  end
  
  test "requirejs_include_tag can appear only once" do
    assert_raises Requirejs::MultipleIncludeError do
      render :text => "#{requirejs_include_tag}\n#{requirejs_include_tag}"
    end
  end
end
