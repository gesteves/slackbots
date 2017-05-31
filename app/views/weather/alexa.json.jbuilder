json.array! [1] do |f|
  json.set! 'updateDate', Time.at(@forecast['currently']['time']).strftime('%Y-%m-%dT%l:%M:%S.%z')
  json.set! 'uid', @forecast['currently']['time'].to_s
  json.set! 'redirectionUrl', "https://darksky.net/#{@forecast['latitude']},#{@forecast['longitude']}"
  json.set! 'titleText', "Weather forecast for #{@address}"

  text_array = []

  unless @forecast['currently'].nil?
    now = @forecast['currently']
    if now['temperature'].round == now['apparentTemperature'].round
      now_text = "Right now: #{now['summary'].force_encoding('UTF-8')}, #{now['temperature'].round}°, #{(now['humidity'] * 100).to_i}% humidity, dew point #{now['dewPoint'].round}°"
    else
      now_text = "Right now: #{now['summary'].force_encoding('UTF-8')}, #{now['temperature'].round}° (feels like #{now['apparentTemperature'].round}°), #{(now['humidity'] * 100).to_i}% humidity, dew point #{now['dewPoint'].round}°"
    end
    text_array << now_text
  end

  unless @forecast['minutely'].nil?
    text_array << "Next hour: #{@forecast['minutely']['summary'].force_encoding('UTF-8')}"
  end

  unless @forecast['hourly'].nil?
    text_array << "Next 24 hours: #{@forecast['hourly']['summary'].force_encoding('UTF-8')}"
  end

  json.set! 'mainText', text_array.join("\n\n")
end
