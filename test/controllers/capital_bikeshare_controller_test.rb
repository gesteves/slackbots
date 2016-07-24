require 'test_helper'

class CapitalBikeshareControllerTest < ActionDispatch::IntegrationTest
  test "should get slash" do
    get capital_bikeshare_slash_url
    assert_response :success
  end

  test "should get auth" do
    get capital_bikeshare_auth_url
    assert_response :success
  end

end
