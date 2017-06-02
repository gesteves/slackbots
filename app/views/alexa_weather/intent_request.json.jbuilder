json.version '1.0'
json.response do
  json.set! 'outputSpeech' do
    if @forecast.nil?
      json.type 'PlainText'
      json.text "Sorry, I couldn't get your forecast."
    else
      json.type 'SSML'
      json.ssml ssml_forecast(@forecast)
    end
  end
end
