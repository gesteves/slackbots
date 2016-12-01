require 'test_helper'

class PollyControllerTest < ActionDispatch::IntegrationTest
  test "should get slash" do
    get polly_slash_url
    assert_response :success
  end

  test "should get auth" do
    get polly_auth_url
    assert_response :success
  end

end
