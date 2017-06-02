class Weather
  def search(location)
    if location.match(/\s+in\s+(celsius|c|metric|si|)$/i)
      location.sub!(/\s+in\s+(celsius|c|metric|si)$/i, '')
      unit_system = 'si'
    else
      unit_system = 'us'
    end

    gmaps_response = GoogleMaps.new.location(location)
    gmaps = JSON.parse(gmaps_response)
    response = if gmaps['status'] == 'OK'
      formatted_address = gmaps['results'][0]['formatted_address']
      lat = gmaps['results'][0]['geometry']['location']['lat']
      long = gmaps['results'][0]['geometry']['location']['lng']

      forecast = JSON.parse(HTTParty.get("https://api.darksky.net/forecast/#{ENV['DARKSKY_API_KEY']}/#{lat},#{long}").body)

      build_response(formatted_address, lat, long, forecast)
    else
      puts gmaps_response
      { text: 'Sorry, I don’t understand that address.', response_type: 'ephemeral' }
    end
  end

  def alexa_search(location)
    gmaps_response = GoogleMaps.new.location(location)
    gmaps = JSON.parse(gmaps_response)
    response = if gmaps['status'] == 'OK'
      formatted_address = gmaps['results'][0]['formatted_address']
      lat = gmaps['results'][0]['geometry']['location']['lat']
      long = gmaps['results'][0]['geometry']['location']['lng']
      forecast = JSON.parse(HTTParty.get("https://api.darksky.net/forecast/#{ENV['DARKSKY_API_KEY']}/#{lat},#{long}").body)
      address_components = []
      address_components << gmaps['results'][0]['address_components'].select { |ac| ac['types'].include? 'locality' }.try(:first).try(:[], 'long_name')
      address_components << gmaps['results'][0]['address_components'].select { |ac| ac['types'].include? 'administrative_area_level_1' }.try(:first).try(:[], 'long_name')
      address_components << gmaps['results'][0]['address_components'].select { |ac| ac['types'].include? 'country' }.try(:first).try(:[], 'long_name')
      forecast['address'] =  address_components.join(', ')
      forecast
    else
      puts gmaps_response
      []
    end
  end

  private

  def build_response(address, lat, long, forecast)
    attachments = []
    attachment = { fallback: "Weather forecast for #{address}: https://darksky.net/#{lat},#{long}",
                   color: color(forecast['currently'], forecast['flags']['units']),
                   title: "Weather forecast for #{address}",
                   title_link: "https://darksky.net/#{lat},#{long}",
                   author_name: 'Powered by Dark Sky',
                   author_link: 'https://darksky.net/poweredby/' }
    fields = []

    unless forecast['alerts'].nil?
      alerts = forecast['alerts'].map { |alert| "<#{alert['uri']}|#{alert['title']}>" }.join("\n")
      fields << { title: 'Alerts ', value: alerts }
    end

    unless forecast['currently'].nil?
      now = forecast['currently']
      if now['temperature'].round == now['apparentTemperature'].round
        now_text = "#{now['summary'].force_encoding('UTF-8')}, #{now['temperature'].round}°, #{(now['humidity'] * 100).to_i}% humidity, dew point #{now['dewPoint'].round}°"
      else
        now_text = "#{now['summary'].force_encoding('UTF-8')}, #{now['temperature'].round}° (feels like #{now['apparentTemperature'].round}°), #{(now['humidity'] * 100).to_i}% humidity, dew point #{now['dewPoint'].round}°"
      end
      fields << { title: 'Right now', value: now_text }
    end

    unless forecast['minutely'].nil?
      fields << { title: 'Next hour', value: forecast['minutely']['summary'].force_encoding('UTF-8') }
    end

    unless forecast['hourly'].nil?
      fields << { title: 'Next 24 hours', value: forecast['hourly']['summary'].force_encoding('UTF-8') }
    end

    unless forecast['daily'].nil?
      fields << { title: 'Next 7 days', value: forecast['daily']['summary'].force_encoding('UTF-8') }
    end

    attachment[:fields] = fields

    if !forecast['currently'].nil? && ['clear-day', 'clear-night', 'rain', 'snow', 'wind', 'fog', 'cloudy', 'partly-cloudy-day', 'partly-cloudy-night'].include?(forecast['currently']['icon'])
      image_path = ActionController::Base.helpers.image_path("weather/#{forecast['currently']['icon']}.png")
      attachment[:thumb_url] = "https://#{ENV['HOST']}#{image_path}"
    end

    attachments << attachment

    { response_type: 'in_channel', attachments: attachments }
  end

  def color(currently, units = nil)
    colors = ['#011892', '#011A94', '#011D96', '#012099', '#01259D', '#0129A1', '#012DA5', '#0132A9', '#0137AE', '#003CB2', '#0041B7', '#0046BB', '#004ABF', '#004FC3', '#0052C6', '#0055C9', '#0058CB', '#005ACD', '#015DCF', '#0061D2', '#0065D5', '#0068D9', '#006DDD', '#0072E1', '#0077E5', '#007BE9', '#0081ED', '#0085F1', '#0089F4', '#008DF7', '#0090FB', '#0094FD', '#0096FE', '#0096FC', '#0096F9', '#0096F4', '#0095F0', '#0095EA', '#0094E5', '#0095DF', '#0094D9', '#0094D3', '#0094CD', '#0093C6', '#0093C0', '#0093BA', '#0093B4', '#0093AE', '#0092A8', '#0092A3', '#00919E', '#00929A', '#009296', '#019193', '#01918C', '#009182', '#009175', '#009065', '#008F55', '#008F45', '#008F34', '#008F24', '#008F16', '#008E0B', '#008E02', '#058E00', '#0E8E00', '#188F00', '#248E01', '#318E00', '#3E8F00', '#4C8F01', '#598F00', '#678F00', '#739000', '#7E9000', '#879000', '#8F9000', '#979000', '#A39000', '#B39100', '#C49100', '#D59200', '#E69300', '#F49300', '#FD9200', '#FB8E00', '#F38501', '#EB7A00', '#E26F00', '#D96400', '#D15B00', '#CC5400', '#C74E00', '#BF4400', '#B63900', '#AC2D00', '#A22100', '#991800', '#931200']
    if currently.nil?
      color = '#CCC'
    else
      t = units == 'si' ? ((currently['apparentTemperature'] * (9.0/5.0)) + 32.0).round.to_i : currently['apparentTemperature'].round.to_i
      index = [[0, t].max, colors.size - 1].min
      color = colors[index]
    end
    color
  end
end
