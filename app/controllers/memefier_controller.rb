class MemefierController < ApplicationController

  def memefy
    if params[:token] == ENV['MEMEFIER_VERIFICATION_TOKEN'] || Rails.env.development?
      query = params[:text].strip
      if query == '' || query == 'help'
        response = { text: "Type a publicly accessible image URL and the quote you want to put on it", response_type: 'ephemeral' }
      else
        response = Memefier.new.memefy(query)
      end
      $mixpanel.track(params[:user_id], params[:command]) unless Rails.env.development?
      render json: response, status: 200
    else
      render text: 'Unauthorized', status: 401
    end
  end

  def auth
    if params[:code].present?
      token = get_slack_access_token(params[:code], ENV['MEMEFIER_CLIENT_ID'], ENV['MEMEFIER_CLIENT_SECRET'], memefier_auth_url)
      notice = token['ok'].present? ? 'The image memes command have been added to your Slack. Woohoo!' : 'D’oh! Authentication failed. Try again!'
    else
      notice = 'Authentication failed. Try again!'
    end
    redirect_to root_url, notice: notice
  end

end
