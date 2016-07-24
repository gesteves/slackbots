require 'test_helper'

class WeatherControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get weather_index_url
    assert_response :success
  end

  test "should get slash" do
    get weather_slash_url
    assert_response :success
  end

  test "should get auth" do
    get weather_auth_url
    assert_response :success
  end

end
