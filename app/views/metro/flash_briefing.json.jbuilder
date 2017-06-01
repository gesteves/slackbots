json.array! [1]  do |a|
  json.set! 'updateDate', DateTime.parse(@alerts['Incidents'][0]['DateUpdated'] + '-0400').utc.strftime('%Y-%m-%dT%H:%M:%S.%z')
  json.set! 'uid', @alerts['Incidents'][0]['IncidentID']
  json.set! 'titleText', 'Service Alert'
  json.set! 'mainText', @alerts['Incidents'].map { |i| i['Description'] }.join("\n\n").gsub('btwn', 'between').gsub('svc', 'service').gsub("\u0026", 'and')
end
