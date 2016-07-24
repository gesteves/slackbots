class ApplicationController < ActionController::Base
  helper_method :get_slack_access_token

  def get_slack_access_token(code, client_id, client_secret, redirect_uri)
    response = HTTParty.get("https://slack.com/api/oauth.access?code=#{code}&client_id=#{client_id}&client_secret=#{client_secret}&redirect_uri=#{redirect_uri}")
    JSON.parse(response.body)
  end

  def default_url_options
    { host: ENV['HOST'] }
  end
end
