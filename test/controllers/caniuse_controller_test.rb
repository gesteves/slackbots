require 'test_helper'

class CaniuseControllerTest < ActionDispatch::IntegrationTest
  test "should get slash" do
    get caniuse_slash_url
    assert_response :success
  end

end
