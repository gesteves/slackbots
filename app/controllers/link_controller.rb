class LinkController < ApplicationController
  def slash
    if params[:token] == ENV['LINK_VERIFICATION_TOKEN'] || Rails.env.development?
      response = { text: params.to_s, response_type: 'ephemeral' }
      $mixpanel.track(params[:user_id], params[:command]) if params[:user_id].present? && params[:command].present?
      render json: response, status: 200
    else
      render text: 'Unauthorized', status: 401
    end
  end

  def auth
    if params[:code].present?
      token = get_slack_access_token(params[:code], ENV['LINK_CLIENT_ID'], ENV['LINK_CLIENT_SECRET'], link_auth_url)
      notice = token['ok'].present? ? 'The /linkhere command has been added to your Slack. Yay!' : 'Authentication failed. Try again!'
    else
      notice = 'Authentication failed. Try again!'
    end
    redirect_to root_url, notice: notice
  end
end
