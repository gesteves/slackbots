json.version '1.0'
json.response do
  json.set! 'outputSpeech' do
    json.type 'PlainText'
    json.text 'What would you like to know?'
  end
  json.set! 'shouldEndSession', false
end
