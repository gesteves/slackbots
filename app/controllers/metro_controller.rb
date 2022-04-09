class MetroController < ApplicationController
  def slash
    begin
      if params[:token] == ENV['METRO_VERIFICATION_TOKEN'] || Rails.env.development?
        query = params[:text].strip
        if query == '' || query == 'help'
          response = { text: "Search for a Metro station by name to see status of trains at that station. For example, `#{params[:command]} Metro Center`. Use `#{params[:command]} status` to see current service alerts and advisories.", response_type: 'ephemeral' }
        elsif query == 'random'
          response = Wmata.new.random
        elsif query == 'alerts' || query == 'status'
          response = Wmata.new.alerts
        else
          response = Wmata.new.station(query)
        end
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
      token = get_slack_access_token(params[:code], ENV['METRO_CLIENT_ID'], ENV['METRO_CLIENT_SECRET'], metro_auth_url)
      notice = token['ok'].present? ? 'The /metro command has been added to your Slack. Yay!' : 'Authentication failed. Try again!'
    else
      notice = 'Authentication failed. Try again!'
    end
    redirect_to root_url, notice: notice
  end
end
