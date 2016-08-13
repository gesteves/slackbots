class CapitalBikeshareController < ApplicationController

  def slash
    if params[:token] == ENV['CABI_VERIFICATION_TOKEN'] || Rails.env.development?
      query = params[:text].sub(/^\s*(in|for|at)\s+/, '').strip
      if query == '' || query == 'help'
        response = { text: "Enter an address to find the closest Capital Bikeshare dock with bikes. For example, `#{params[:command]} near 1600 Pennsylvania Avenue NW, Washington, DC`", response_type: 'ephemeral' }
      else
        response = Cabi.new.search(query)
      end
      $mixpanel.track(params[:user_id], params[:command]) if params[:user_id].present? && params[:command].present?
      render json: response, status: 200
    else
      render text: 'Unauthorized', status: 401
    end
  end

  def auth
    if params[:code].present?
      token = get_slack_access_token(params[:code], ENV['CABI_CLIENT_ID'], ENV['CABI_CLIENT_SECRET'], cabi_auth_url)
      notice = token['ok'].present? ? 'The /cabi command has been added to your Slack. Yay!' : 'Authentication failed. Try again!'
    else
      notice = 'Authentication failed. Try again!'
    end
    redirect_to root_url, notice: notice
  end

end
