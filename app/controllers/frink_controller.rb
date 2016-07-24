class FrinkController < ApplicationController

  def index
    @page_title = '/frink: Simpsons gifs in Slack'
  end

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
    @page_title = 'Auth failed!'
    if params[:code].present?
      token = get_access_token(params[:code])
      if token['ok'].present?
        @page_title = 'Success!'
        render 'success'
      else
        render 'fail'
      end
    else
      render 'fail'
    end
  end

  private

  def get_access_token(code)
    response = HTTParty.get("https://slack.com/api/oauth.access?code=#{code}&client_id=#{ENV['FRINK_CLIENT_ID']}&client_secret=#{ENV['FRINK_CLIENT_SECRET']}&redirect_uri=#{frink_auth_url}")
    JSON.parse(response.body)
  end

end
