class BeerController < ApplicationController
  def slash
    if params[:token] == ENV['BEER_VERIFICATION_TOKEN'] || Rails.env.development?
      query = params[:text].strip
      if query == '' || query == 'help'
        response = { text: "Search for a beer by brewery and beer name. For example, `#{params[:command]} Firestone Walker Double Jack`", response_type: 'ephemeral' }
      else
        response = Untappd.new.search(query)
      end
      $mixpanel.track(params[:user_id], params[:command])
      render json: response, status: 200
    else
      render text: 'Unauthorized', status: 401
    end
  end

  def auth
    if params[:code].present?
      token = get_slack_access_token(params[:code], ENV['BEER_CLIENT_ID'], ENV['BEER_CLIENT_SECRET'], cabi_auth_url)
      notice = token['ok'].present? ? 'The /untappd command has been added to your Slack. Yay!' : 'Authentication failed. Try again!'
    else
      notice = 'Authentication failed. Try again!'
    end
    redirect_to root_url, notice: notice
  end
end