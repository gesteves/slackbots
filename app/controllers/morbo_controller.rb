class MorboController < ApplicationController

  def slash
    if params[:token] == ENV['MORBO_VERIFICATION_TOKEN'] || Rails.env.development?
      query = params[:text].strip
      if query == '' || query == 'help'
        response = { text: "Type a quote from Futurama to find it in gif form, like `#{params[:command]} hooray a happy ending for rich people!`", response_type: 'ephemeral' }
      else
        frink = Frink.new(site: 'https://morbotron.com', line_width: 24)
        response = frink.search(query)
      end
      $mixpanel.track(params[:user_id], params[:command]) if params[:user_id].present? && params[:command].present?
      render json: response, status: 200
    else
      render text: 'Unauthorized', status: 401
    end
  end

  def auth
    if params[:code].present?
      token = get_slack_access_token(params[:code], ENV['MORBO_CLIENT_ID'], ENV['MORBO_CLIENT_SECRET'], morbo_auth_url)
      notice = token['ok'].present? ? 'The /morbo command has been added to your Slack. Woohoo!' : 'D’oh! Authentication failed. Try again!'
    else
      notice = 'Authentication failed. Try again!'
    end
    redirect_to root_url, notice: notice
  end

end
