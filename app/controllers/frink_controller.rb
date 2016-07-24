class FrinkController < ApplicationController

  def slash
    if params[:token] == ENV['FRINK_VERIFICATION_TOKEN'] || Rails.env.development?
      query = params[:text].strip
      if query == '' || query == 'help'
        response = { text: "D'oh! You have to enter a quote from The Simpsons, like `#{params[:command]} everything's comin' up Milhouse!`", response_type: 'ephemeral' }
      else
        response = Frink.new.search(query)
      end
      render json: response, status: 200
    else
      render text: 'Unauthorized', status: 401
    end
  end

  def auth
    if params[:code].present?
      token = get_slack_access_token(params[:code], ENV['FRINK_CLIENT_ID'], ENV['FRINK_CLIENT_SECRET'], frink_auth_url)
      notice = token['ok'].present? ? 'The /frink command has been added to your Slack. Woohoo!' : 'D’oh! Authentication failed. Try again!'
    else
      notice = 'Authentication failed. Try again!'
    end
    redirect_to root_url, notice: notice
  end

end
