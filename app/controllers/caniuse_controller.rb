class CaniuseController < ApplicationController
  def slash
    if params[:token] == ENV['CANIUSE_VERIFICATION_TOKEN'] || Rails.env.development?
      query = params[:text].strip
      if query == '' || query == 'help'
        response = { text: "Type a browser feature to see the support data for it, for example, `#{params[:command]} flexbox`", response_type: 'ephemeral' }
      else
        response = Caniuse.new.search(query)
      end
      $mixpanel.track(params[:user_id], params[:command])
      render json: response, status: 200
    else
      render text: 'Unauthorized', status: 401
    end
  end

  def auth
    if params[:code].present?
      token = get_slack_access_token(params[:code], ENV['CANIUSE_CLIENT_ID'], ENV['CANIUSE_CLIENT_SECRET'], caniuse_auth_url)
      notice = token['ok'].present? ? 'The /caniuse command has been added to your Slack. Yay!' : 'Authentication failed. Try again!'
    else
      notice = 'Authentication failed. Try again!'
    end
    redirect_to root_url, notice: notice
  end
end
