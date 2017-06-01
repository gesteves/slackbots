json.array! @alerts['Incidents'] do |i|
  json.set! 'updateDate', DateTime.parse(i['DateUpdated'] + '-0400').utc.strftime('%Y-%m-%dT%H:%M:%S.%z')
  json.set! 'uid', i['IncidentID']
  json.set! 'titleText', 'Service Alert'
  json.set! 'mainText', i['Description']
end
