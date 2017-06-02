class AlexaWeatherController < ApplicationController
  def flash
    expires_in 5.minutes, public: true
    @forecast = get_forecast(params[:city].gsub('-', ' '))
    respond_to do |format|
      format.json
    end
  end

  def index
    request_time = Time.parse(params['request']['timestamp'])
    application_id = params['session']['application']['applicationId']

    if (Time.now - request_time > 150 || application_id != ENV['ALEXA_WEATHER_APP_ID'])
      render plain: 'Bad Request', status: 400
    else
      logger.info "#{params['request']['type']} received."
      case params['request']['type']
      when 'LaunchRequest'
        launch_request(params)
      when 'IntentRequest'
        intent_request(params)
      when 'SessionEndedRequest'
        session_ended_request(params)
      end
    end
  end

  private

  def launch_request(params)
    user_id = params['session']['user']['userId']
    device_id = params['context']['System'].try(:[], 'device').try(:[], 'deviceId')
    consent_token = params['session']['user'].try(:[], 'permissions').try(:[], 'consentToken')
    save_consent_token(user_id, device_id, consent_token)
    address = get_alexa_address(user_id, device_id)
    if address.nil?
      @message = "To get your forecast, set an address on your Echo and give Nimbus permission to access it. Or, ask Nimbus for the weather in a specific city."
    else
      @forecast = get_forecast(address)
    end
    respond_to do |format|
      format.json {
        render 'intent_request'
      }
    end
  end

  def intent_request(params)
    user_id = params['session']['user']['userId']
    device_id = params['context']['System'].try(:[], 'device').try(:[], 'deviceId')
    address = params['request']['intent']['slots']['address']['value'] || params['request']['intent']['slots']['city']['value']
    address = get_alexa_address(user_id, device_id) if address.nil? && user_id.present? && device_id.present?
    if address.nil?
      @message = "To get your forecast, set an address on your Echo and give Nimbus permission to access it. Or, ask Nimbus for the weather in a specific city."
    else
      @forecast = get_forecast(address)
    end
    respond_to do |format|
      format.json {
        render 'intent_request'
      }
    end
  end

  def session_ended_request(params)
    respond_to do |format|
      format.json {
        render 'session_ended_request'
      }
    end
  end

  def get_alexa_address(user_id, device_id)
    user = $redis.hgetall("alexa:user:#{user_id}:#{device_id}")
    if user.present? && user['device_id'].present? && user['consent_token'].present?
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
        address
      else
        nil
      end
    else
      nil
    end
  end

  def save_consent_token(user_id, device_id, consent_token)
    $redis.hmset("alexa:user:#{user_id}:#{device_id}", 'user_id', user_id, 'device_id', device_id, 'consent_token', consent_token)
  end

  def get_forecast(location)
    gmaps_response = GoogleMaps.new.location(location)
    gmaps = JSON.parse(gmaps_response)
    response = if gmaps['status'] == 'OK'
      formatted_address = gmaps['results'][0]['formatted_address']
      lat = gmaps['results'][0]['geometry']['location']['lat']
      long = gmaps['results'][0]['geometry']['location']['lng']
      forecast = JSON.parse(HTTParty.get("https://api.darksky.net/forecast/#{ENV['DARKSKY_API_KEY']}/#{lat},#{long}").body)
      forecast['formattedAddress'] = formatted_address
      forecast
    else
      nil
    end
  end
end
