require 'test_helper'

class RequirejsRailsTest < ActiveSupport::TestCase
  test "truth" do
    assert_kind_of Module, Requirejs
    assert_kind_of Module, Requirejs::Rails
  end
end
