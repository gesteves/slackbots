class LinkController < ApplicationController
  def slash
    begin
      if params[:token] == ENV['LINK_VERIFICATION_TOKEN'] || Rails.env.development?
        location = if params[:channel_id] =~ /^C/
          'channel'
        elsif params[:channel_id] =~ /^G/
          'private group'
        elsif params[:channel_id] =~ /^D/
          'direct message'
        else
          'location'
        end
        url = "slack://channel?team=#{params[:team_id]}&id=#{params[:channel_id]}"
        response = { text: "Here’s your link to this #{location}: #{url}", response_type: 'ephemeral' }
        render json: response, status: 200
      else
        render text: 'Unauthorized', status: 401
      end
    rescue => e
      response = { text: "Oops, something went wrong: `#{e}`", response_type: 'ephemeral' }
      render json: response, status: 200
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
