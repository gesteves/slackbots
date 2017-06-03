class AlexaWeatherController < ApplicationController

  def index
    request_time = Time.parse(params['request']['timestamp'])
    application_id = params['session']['application']['applicationId']

    # Check that the request is valid:
    # was sent less than 150 seconds ago, and the app id matches
    # TODO: Check the signature https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/developing-an-alexa-skill-as-a-web-service#checking-the-signature-of-the-request
    if (Time.now - request_time > 150 || application_id != ENV['ALEXA_WEATHER_APP_ID'])
      render plain: 'Bad Request', status: 400
    else
      # Handle each type of request.
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

  # Launch request, i.e. "Alexa, open Dark Sky"
  # Store the consent token from the request so I can use it later to access
  # the Echo's address.
  def launch_request(params)
    user_id = params['session']['user']['userId']
    device_id = params['context']['System'].try(:[], 'device').try(:[], 'deviceId')
    consent_token = params['session']['user'].try(:[], 'permissions').try(:[], 'consentToken')
    save_consent_token(user_id, device_id, consent_token)
    respond_to do |format|
      format.json {
        render 'launch_request'
      }
    end
  end

  # Handle each type of intent. For now the only one is `DarkSkyForecast`
  # e.g. "what's the weather in DC"
  def intent_request(params)
    case params['request']['intent']['name']
    when 'DarkSkyForecast'
      forecast_intent(params)
    end
  end

  # Handle a forecast intent. If the user included a city ("what's the weather in DC"),
  # or an address ("what's the address in 1600 pennsylvania avenue"), use that
  # to get the forecast. If the user included neither, use the user id and device id
  # to get the consent token received in the launch request, and get the address
  # of the Echo. If it can't get obtained (the Echo doesn't have it or the user
  # did not give permissions), show an error.
  # Otherwise use the address to get the forecast.
  def forecast_intent(params)
    user_id = params['session']['user']['userId']
    device_id = params['context'].try(:[], 'System').try(:[], 'device').try(:[], 'deviceId')
    address = params['request']['intent']['slots']['address']['value'] || params['request']['intent']['slots']['city']['value']
    address = get_alexa_address(user_id, device_id) if address.nil? && user_id.present? && device_id.present?
    if address.nil?
      @message = "To get your forecast, set an address on your Echo and give Dark Sky permission to access it. Or, ask Dark Sky for the weather in a specific city."
    else
      @forecast = get_forecast(address)
      @message = "Couldn\'t get the forecast for that location." if @forecast.nil?
    end
    respond_to do |format|
      format.json {
        render 'forecast_intent'
      }
    end
  end

  # Nothing, just say goodbye if the user ends the session.
  def session_ended_request(params)
    respond_to do |format|
      format.json {
        render 'session_ended_request'
      }
    end
  end

  # Save the consent token for the user and device in Redis.
  def save_consent_token(user_id, device_id, consent_token)
    $redis.hmset("alexa:user:#{user_id}:#{device_id}", 'user_id', user_id, 'device_id', device_id, 'consent_token', consent_token)
  end

  # Use the user and device's consent token to make a request for the
  # device's address, and return it as a string.
  def get_alexa_address(user_id, device_id)
    user = $redis.hgetall("alexa:user:#{user_id}:#{device_id}")
    if user.present? && user['device_id'].present? && user['consent_token'].present?
      device_id = user['device_id']
      consent_token = user['consent_token']
      response = HTTParty.get("https://api.amazonalexa.com/v1/devices/#{device_id}/settings/address", headers: { 'Authorization': "Bearer #{consent_token}"})
      if response.code == 200
        body = JSON.parse(response.body)
        address = []
        address << body['addressLine1']
        address << body['addressLine2']
        address << body['addressLine3']
        address << body['city']
        address << body['stateOrRegion']
        address << body['countryCode']
        address << body['postalCode']
        address.reject { |a| a.blank? }.join(', ')
      else
        nil
      end
    else
      nil
    end
  end

  # Get the Dark Sky forecast for a given location.
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
