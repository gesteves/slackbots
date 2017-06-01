json.array! [1] do |x|
  json.set! 'updateDate', Time.now.strftime('%Y-%m-%dT%l:%M:%S.%z')
  json.set! 'uid', @alerts['Incidents'][0]['IncidentID']
  json.set! 'titleText', 'Metro Alerts'
  json.set! 'mainText', @alerts['Incidents'].map { |i| i['Description'] }.join("\n")
end
