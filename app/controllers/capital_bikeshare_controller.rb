class CapitalBikeshareController < ApplicationController

  def index
    @page_title = '/cabi: Capital Bikeshare in Slack'
  end

  def slash
    if params[:token] == ENV['CABI_VERIFICATION_TOKEN'] || Rails.env.development?
      query = params[:text].sub(/^\s*(in|for|at)\s+/, '').strip
      if query == '' || query == 'help'
        response = { text: 'Enter an address to get the closest Capital Bikeshare dock with bikes. For example, `/cabi near 1600 Pennsylvania Avenue NW, Washington, DC`', response_type: 'ephemeral' }
      else
        response = Cabi.new.search(query)
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
    response = HTTParty.get("https://slack.com/api/oauth.access?code=#{code}&client_id=#{ENV['CABI_CLIENT_ID']}&client_secret=#{ENV['CABI_CLIENT_SECRET']}&redirect_uri=#{cabi_auth_url}")
    JSON.parse(response.body)
  end
end
