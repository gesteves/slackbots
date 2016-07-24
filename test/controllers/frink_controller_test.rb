require 'test_helper'

class FrinkControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get frink_index_url
    assert_response :success
  end

  test "should get slash" do
    get frink_slash_url
    assert_response :success
  end

  test "should get auth" do
    get frink_auth_url
    assert_response :success
  end

end
