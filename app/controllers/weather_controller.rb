class WeatherController < ApplicationController
  def index
    @page_title = '/weather: Weather Forecasts in Slack'
  end

  def slash
    if params[:token] == ENV['WEATHER_VERIFICATION_TOKEN'] || Rails.env.development?
      query = params[:text].sub(/^\s*(in|for|at)\s+/, '').strip
      if query == '' || query == 'help'
        response = { text: 'Enter a location to get the current weather forecast for it. You can enter just a city or zip code, or a full address. For example, `/weather in 1600 Pennsylvania Avenue NW, Washington, DC`, `/weather in washington, dc`, or `/weather in 20036`. You can also specify if you want your results in celsius, like `/weather in new york in celsius`.', response_type: 'ephemeral' }
      else
        response = Weather.new.search(query)
      end
      render json: response, status: 200
    else
      render text: 'Unauthorized', status: 401
    end
  end

  def auth
    @page_title = 'Auth failed!'
    if params[:code].present?
      token = get_access_token(params[:code])
      if token['ok'].present?
        @page_title = 'Success!'
        render 'success'
      else
        render 'fail'
      end
    else
      render 'fail'
    end
  end

  private

  def get_access_token(code)
    response = HTTParty.get("https://slack.com/api/oauth.access?code=#{code}&client_id=#{ENV['WEATHER_CLIENT_ID']}&client_secret=#{ENV['WEATHER_CLIENT_SECRET']}&redirect_uri=#{weather_auth_url}")
    JSON.parse(response.body)
  end
end
