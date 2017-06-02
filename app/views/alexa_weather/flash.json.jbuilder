json.array! [1] do |f|
  json.set! 'updateDate', Time.at(@forecast['currently']['time']).strftime('%Y-%m-%dT%H:%M:%S.%z')
  json.set! 'uid', @forecast['currently']['time'].to_s
  json.set! 'redirectionUrl', "https://darksky.net/#{@forecast['latitude']},#{@forecast['longitude']}"
  json.set! 'titleText', "Weather forecast for #{@forecast['formattedAddress']}"

  text_array = ["Here's the forecast for #{@forecast['formattedAddress']}."]

  unless @forecast['currently'].nil?
    now = @forecast['currently']
    if now['temperature'].round == now['apparentTemperature'].round
      now_text = "Right now: #{now['summary']}, #{now['temperature'].round}°, #{(now['humidity'] * 100).to_i}% humidity, dew point: #{now['dewPoint'].round}°"
    else
      now_text = "Right now: #{now['summary']}, #{now['temperature'].round}° (feels like #{now['apparentTemperature'].round}°), #{(now['humidity'] * 100).to_i}% humidity, dew point #{now['dewPoint'].round}°"
    end
    text_array << now_text
  end

  unless @forecast['minutely'].nil?
    text_array << "Next hour: #{@forecast['minutely']['summary']}"
  end

  unless @forecast['hourly'].nil?
    max = @forecast['hourly']['data'].map { |d| d['apparentTemperature'] }.max
    min = @forecast['hourly']['data'].map { |d| d['apparentTemperature'] }.min
    text_array << "Next 24 hours: #{@forecast['hourly']['summary'].gsub(/\.$/, '')}, with a high of #{max.round}° and and low of #{min.round}°."
  end

  unless @forecast['daily'].nil?
    text_array << "Next 7 days: #{@forecast['daily']['summary']}"
  end

  json.set! 'mainText', text_array.join("\n\n")
end
