require 'test_helper'

class LinkControllerTest < ActionDispatch::IntegrationTest
  test "should get slash" do
    get link_slash_url
    assert_response :success
  end

  test "should get auth" do
    get link_auth_url
    assert_response :success
  end

end
