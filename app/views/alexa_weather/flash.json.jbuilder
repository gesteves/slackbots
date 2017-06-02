json.array! [1] do |f|
  json.set! 'updateDate', Time.at(@forecast['currently']['time']).strftime('%Y-%m-%dT%H:%M:%S.%z')
  json.set! 'uid', @forecast['currently']['time'].to_s
  json.set! 'redirectionUrl', "https://darksky.net/#{@forecast['latitude']},#{@forecast['longitude']}"
  json.set! 'titleText', "Weather forecast for #{@forecast['formattedAddress']}"
  json.set! 'mainText', forecast_plain(@forecast)
end
