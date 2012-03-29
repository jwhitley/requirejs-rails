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
    assert_equal Requirejs::Rails::LibVersion, context.eval("require.version")
  end

  test "CHANGELOG up to date" do
    changelog_match = (/^# v#{Requirejs::Rails::Version}/ =~ Pathname.new(__FILE__+'/../../CHANGELOG.md').cleanpath.read)
    assert changelog_match, "CHANGELOG has no section for v#{Requirejs::Rails::Version}"
  end
end

class RequirejsRailsConfigTest < ActiveSupport::TestCase
  def setup
    @cfg = Requirejs::Rails::Config.new
  end

  test "config accepts known loaders" do
    @cfg.loader = :almond
    assert_equal :almond, @cfg.loader
  end

  test "config rejects bad loaders" do
    assert_raises Requirejs::ConfigError do
      @cfg.loader = :wombat
    end
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
  
  test "requirejs_include_tag_with_block" do
    test_block = Proc.new do |controller| 
      { 'class' => controller.class.to_s.demodulize }
    end

    render :text => wrap(requirejs_include_tag("application", &test_block))
    assert_select "script:last-of-type[src^=/javascripts/require.js][data-main^=/javascripts/application.js]", :count => 1
    assert_select "script:last-of-type[src^=/javascripts/require.js][data-class^=TestController]", :count => 1
  end

  test "requirejs_include_tag can appear only once" do
    assert_raises Requirejs::MultipleIncludeError do
      render :text => "#{requirejs_include_tag}\n#{requirejs_include_tag}"
    end
  end
end
