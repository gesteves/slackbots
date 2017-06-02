class WeatherController < ApplicationController

  def slash
    begin
      if params[:token] == ENV['WEATHER_VERIFICATION_TOKEN'] || Rails.env.development?
        query = params[:text].sub(/^\s*(in|for|at)\s+/, '').strip
        if query == '' || query == 'help'
          response = { text: "Enter a location to get the current weather forecast for it. You can enter just a city or zip code, or a full address. For example, `#{params[:command]} in 1600 Pennsylvania Avenue NW, Washington, DC`, `#{params[:command]} in washington, dc`, or `#{params[:command]} in 20036`. You can also specify if you want your results in celsius, like `#{params[:command]} in new york in celsius`.", response_type: 'ephemeral' }
        else
          response = Weather.new.search(query)
        end
        $mixpanel.track(params[:user_id], params[:command]) if params[:user_id].present? && params[:command].present?
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
      token = get_slack_access_token(params[:code], ENV['WEATHER_CLIENT_ID'], ENV['WEATHER_CLIENT_SECRET'], weather_auth_url)
      notice = token['ok'].present? ? 'The /weather command has been added to your Slack. Yay!' : 'Authentication failed. Try again!'
    else
      notice = 'Authentication failed. Try again!'
    end
    redirect_to root_url, notice: notice
  end

  def flash_briefing
    expires_in 5.minutes, public: true
    @address = ENV['WEATHER_ADDRESS']
    @forecast = Weather.new.alexa_search(@address)
    respond_to do |format|
      format.json
    end
  end

  def alexa
    expires_now
    logger.info "#{params['request']['type']} received."
    view = if params['request']['type'] == 'LaunchRequest'
      save_consent_token(params['context']['System']['user']['userId'], params['context']['System']['device']['deviceId'], params['context']['System']['user']['permissions']['consentToken'])
      address = get_alexa_address(params['context']['System']['user']['userId'])
      @forecast = Weather.new.alexa_search(address)
      'intent_request'
    elsif params['request']['type'] == 'IntentRequest'
      address = get_alexa_address(params['session']['user']['userId'])
      @forecast = Weather.new.alexa_search(address)
      'intent_request'
    elsif params['request']['type'] == 'SessionEndedRequest'
      'session_ended_request'
    end
    respond_to do |format|
      format.json {
        render view
      }
    end
  end

  private

  def get_alexa_address(user_id)
    user = $redis.hgetall("alexa:user:#{user_id}")
    if user.present? && user['device_id'].present? && user['consent_token'].present?
      logger.info "User found, requesting address."
      device_id = user['device_id']
      consent_token = user['consent_token']
      response = HTTParty.get("https://api.amazonalexa.com/v1/devices/#{device_id}/settings/address", headers: { 'Authorization': "Bearer #{consent_token}"})
      if response.code == 200
        body = JSON.parse(response.body)
        address = []
        address << body['addressLine1'] unless body['addressLine1'].blank?
        address << body['addressLine2'] unless body['addressLine2'].blank?
        address << body['addressLine3'] unless body['addressLine3'].blank?
        address << body['city'] unless body['city'].blank?
        address << body['stateOrRegion'] unless body['stateOrRegion'].blank?
        address << body['countryCode'] unless body['countryCode'].blank?
        address << body['postalCode'] unless body['postalCode'].blank?
        address = address.join(', ')
        logger.info "Address found: #{address}"
        address
      else
        logger.info "Address not found, status #{response.code}, response: #{response.body}"
        'Washington, DC'
      end
    else
      logger.info "User not found!"
      'Washington, DC'
    end
  end

  def save_consent_token(user_id, device_id, consent_token)
    $redis.hmset("alexa:user:#{user_id}", 'user_id', user_id, 'device_id', device_id, 'consent_token', consent_token)
  end
end
