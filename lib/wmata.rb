class Wmata
  include ActionView::Helpers::TextHelper

  def station(search)
    station_list = get_station_list
    white = Text::WhiteSimilarity.new
    best_match = station_list['Stations'].sort { |a, b| white.similarity(b['Name'], search) <=>  white.similarity(a['Name'], search) }.first
    stations = station_list['Stations'].select { |s| s['Name'] == best_match['Name'] }
    { response_type: 'in_channel', attachments: build_attachments(stations), text: "Next train arrivals at #{best_match['Name']} Metro Station:" }
  end

  private

  def build_attachments(stations)
    attachments = []
    stations.each do |station|
      trains = get_station_trains(station['Code'])
      trains.each do |train|
        attachment = { fallback: "#{train['Line']} – #{train['DestinationName']} – #{train['Min']} min", mrkdwn_in: ['text'] }
        attachment[:color] = line_color(train['Line'])
        fields = [{ value: "#{train['DestinationName']} (#{pluralize(train['Car'], 'car')})", short: true }]
        fields << { value: arrival_to_human(train['Min']), short: true } unless arrival_to_human(train['Min']).nil?
        attachment[:fields] = fields
        attachments << attachment
      end
    end
    attachments
  end

  def line_color(code)
    # RD, BL, YL, OR, GR, or SV
    case code
    when 'RD'
      '#BE1439'
    when 'BL'
      '#0390D5'
    when 'YL'
      '#F8D619'
    when 'OR'
      '#E38A01'
    when 'GR'
      '#00AD4C'
    when 'SV'
      '#A4A4A4'
    else
      '#EEEEEE'
    end
  end

  def arrival_to_human(arrival)
    if arrival == 'ARR'
      'Arriving'
    elsif arrival == 'BRD'
      'Boarding'
    elsif arrival.to_i > 0
      pluralize(arrival.to_i, 'minute')
    end
  end

  def get_station_trains(code)
    response = Rails.cache.fetch("wmata:train_list", expires_in: 1.minute) do
      HTTParty.get('https://api.wmata.com/StationPrediction.svc/json/GetPrediction/All', headers: { api_key: ENV['WMATA_API_KEY']}).body
    end
    trains = JSON.parse(response)['Trains']
    trains.select { |train| train['LocationCode'] == code && train['DestinationCode'].present? && train['Min'].present? }
  end

  def get_station_list
    response = Rails.cache.fetch("wmata:station_list", expires_in: 30.days) do
      HTTParty.get('https://api.wmata.com/Rail.svc/json/jStations', headers: { api_key: ENV['WMATA_API_KEY']}).body
    end
    JSON.parse(response)
  end
end
