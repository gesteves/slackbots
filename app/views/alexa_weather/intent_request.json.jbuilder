json.version '1.0'
json.response do
  if @forecast.nil?
    json.set! 'outputSpeech' do
      json.type 'PlainText'
      json.text "Sorry, I couldn't get your forecast."
    end
  else
    json.set! 'outputSpeech' do
      json.type 'SSML'
      json.ssml forecast_ssml(@forecast)
    end
    json.set! 'card' do
      json.type 'Simple'
      json.title "Weather forecast for #{@forecast['formattedAddress']}"
      json.content forecast_card(@forecast)
    end
  end
end
