class WeatherController < ApplicationController

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
    if params[:code].present?
      token = get_slack_access_token(params[:code], ENV['WEATHER_CLIENT_ID'], ENV['WEATHER_CLIENT_SECRET'], weather_auth_url)
      notice = token['ok'].present? ? 'The /weather command has been added to your Slack. Yay!' : 'Authentication failed. Try again!'
    else
      notice = 'Authentication failed. Try again!'
    end
    redirect_to root_url, notice: notice
  end
end
