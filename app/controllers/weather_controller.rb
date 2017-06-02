class WeatherController < ApplicationController
  def slash
    begin
      if params[:token] == ENV['WEATHER_VERIFICATION_TOKEN'] || Rails.env.development?
        query = params[:text].sub(/^\s*(in|for|at)\s+/, '').strip
        if query == '' || query == 'help'
          response = { text: "Enter a location to get the current weather forecast for it. You can enter just a city or zip code, or a full address. For example, `#{params[:command]} in 1600 Pennsylvania Avenue NW, Washington, DC`, `#{params[:command]} in washington, dc`, or `#{params[:command]} in 20036`. You can also specify if you want your results in celsius, like `#{params[:command]} in new york in celsius`.", response_type: 'ephemeral' }
        else
          response = Weather.new.search(query)
        end
        $mixpanel.track(params[:user_id], params[:command]) if params[:user_id].present? && params[:command].present?
        render json: response, status: 200
      else
        render text: 'Unauthorized', status: 401
      end
    rescue => e
      response = { text: "Oops, something went wrong: `#{e}`", response_type: 'ephemeral' }
      render json: response, status: 200
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
