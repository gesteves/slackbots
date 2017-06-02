json.version '1.0'
json.response do
  json.set! 'outputSpeech' do
    json.type 'SSML'
    json.ssml '<speak>To get the forecast for your location, say "what\'s the weather?". You can also get the weather for a specific location, for example "what\'s the weather in new york?"</speak>'
  end
  json.set! 'shouldEndSession', false
end
