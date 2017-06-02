class AlexaWeatherController < ApplicationController
  def flash
    expires_in 5.minutes, public: true
    @forecast = Weather.new.alexa_search(params[:city].gsub('-', ' '))
    respond_to do |format|
      format.json
    end
  end

  def index
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

  private

  def intent_request(params)
    user_id = params.try(:[], 'session').try(:[], 'user').try(:[], 'userId')
    device_id = params.try(:[], 'context').try(:[], 'System').try(:[], 'device').try(:[], 'deviceId')
    address = params['request']['intent']['slots']['address']['value'] || params['request']['intent']['slots']['city']['value']
    address = get_alexa_address(user_id, device_id) if address.nil? && user_id.present? && device_id.present?
    @forecast = address.nil? ? nil : Weather.new.alexa_search(address)
    respond_to do |format|
      format.json {
        render 'intent_request'
      }
    end
  end

  def launch_request(params)
    user_id = params.try(:[], 'session').try(:[], 'user').try(:[], 'userId')
    device_id = params.try(:[], 'context').try(:[], 'System').try(:[], 'device').try(:[], 'deviceId')
    consent_token = params.try(:[], 'session').try(:[], 'user').try(:[], 'permissions').try(:[], 'consentToken')
    save_consent_token(user_id, device_id, consent_token)
    address = get_alexa_address(user_id, device_id)
    @forecast = address.nil? ? nil : Weather.new.alexa_search(address)
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
end
