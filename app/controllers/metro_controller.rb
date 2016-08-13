class MetroController < ApplicationController
  def slash
    if params[:token] == ENV['METRO_VERIFICATION_TOKEN'] || Rails.env.development?
      query = params[:text].strip
      if query == '' || query == 'help'
        response = { text: "Search for a Metro station by name to see status of trains at that station. For example, `#{params[:command]} Metro Center`", response_type: 'ephemeral' }
      else
        response = Wmata.new.station(query)
      end
      $mixpanel.track(params[:user_id], params[:command]) unless Rails.env.development?
      render json: response, status: 200
    else
      render text: 'Unauthorized', status: 401
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