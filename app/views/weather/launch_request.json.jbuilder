json.version '1.0'
json.response do
  json.set! 'outputSpeech' do
    json.type 'PlainText'
    json.text 'Hello!'
  end
end
