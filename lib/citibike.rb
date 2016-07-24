class Citibike
  include ActiveSupport::Inflector

  def search(location)
    gmaps_response = GoogleMaps.new.location(location)
    gmaps = JSON.parse(gmaps_response)

    response = if gmaps['status'] == 'OK'
      lat = gmaps['results'][0]['geometry']['location']['lat']
      long = gmaps['results'][0]['geometry']['location']['lng']

      # Get station info
      station_info = JSON.parse(get_station_info)['data']['stations']
      # Get station status
      station_status = JSON.parse(get_station_status)['data']['stations']

      stations = (station_info + station_status).group_by { |s| s['station_id'] }.map { |k, v| v.reduce(:merge) }

      # Sort stations by distance
      stations.sort! { |a,b| distance([lat, long], [a['lat'], a['lon']]) <=> distance([lat, long], [b['lat'], b['lon']]) }

      # Get the first one that has > 0 bikes
      station = stations.find { |s| s['num_bikes_available'] > 0 }

      build_response(lat, long, station)
    else
      { text: 'Sorry, I don’t understand that address.', response_type: 'ephemeral' }
    end
  end

  private

  def build_response(lat, long, station)
    name = station['name']
    bikes = station['num_bikes_available']
    docks = station['num_docks_available']
    station_lat = station['lat']
    station_long = station['lon']
    link = "https://maps.google.com?saddr=#{lat},#{long}&daddr=#{station_lat},#{station_long}&dirflg=w"

    attachments = []
    attachment = { fallback: "The nearest Citibike station with bikes is #{name}: #{link}", color: '#1d5b97', pretext: "This is the nearest Citibike station with bikes:", title: name, title_link: link, image_url: GoogleMaps.new.image(station_lat, station_long) }
    fields = []
    fields << { title: 'Available Bikes', value: bikes, short: true }
    fields << { title: 'Available Docks', value: docks, short: true }
    attachment[:fields] = fields
    attachments << attachment

    { response_type: 'in_channel', attachments: attachments }
  end

  # Haversine distance formula from http://stackoverflow.com/a/12969617
  def distance(loc1, loc2)
    rad_per_deg = Math::PI/180  # PI / 180
    rkm = 6371                  # Earth radius in kilometers
    rm = rkm * 1000             # Radius in meters

    dlat_rad = (loc2[0]-loc1[0]) * rad_per_deg  # Delta, converted to rad
    dlon_rad = (loc2[1]-loc1[1]) * rad_per_deg

    lat1_rad, lon1_rad = loc1.map {|i| i * rad_per_deg }
    lat2_rad, lon2_rad = loc2.map {|i| i * rad_per_deg }

    a = Math.sin(dlat_rad/2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad/2)**2
    c = 2 * Math::atan2(Math::sqrt(a), Math::sqrt(1-a))

    rm * c # Delta in meters
  end

  def get_station_info
    Rails.cache.fetch("citibike_station_info", expires_in: 24.hours) do
      HTTParty.get('https://gbfs.citibikenyc.com/gbfs/en/station_information.json').body
    end
  end

  def get_station_status
    Rails.cache.fetch("citibike_station_status", expires_in: 5.minutes) do
      HTTParty.get('https://gbfs.citibikenyc.com/gbfs/en/station_status.json').body
    end
  end
end
