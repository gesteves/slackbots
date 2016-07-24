class CapitalBikeshareController < ApplicationController

  def index
    @page_title = '/cabi: Capital Bikeshare in Slack'
  end

  def slash
    if params[:token] == ENV['CABI_VERIFICATION_TOKEN'] || Rails.env.development?
      query = params[:text].sub(/^\s*(in|for|at)\s+/, '').strip
      if query == '' || query == 'help'
        response = { text: 'Enter an address to get the closest Capital Bikeshare dock with bikes. For example, `/cabi near 1600 Pennsylvania Avenue NW, Washington, DC`', response_type: 'ephemeral' }
      else
        response = search(query)
      end
      render json: response, status: 200
    else
      render text: 'Unauthorized', status: 401
    end
  end

  def auth
    @page_title = 'Auth failed!'
    if params[:code].present?
      token = get_access_token(params[:code])
      if token['ok'].present?
        @page_title = 'Success!'
        render 'success'
      else
        render 'fail'
      end
    else
      render 'fail'
    end
  end

  private

  def search(location)
    gmaps_response = HTTParty.get("http://maps.googleapis.com/maps/api/geocode/json?address=#{URI::encode(location)}&sensor=false").body
    gmaps = JSON.parse(gmaps_response)

    response = if gmaps['status'] == 'OK'
      lat = gmaps['results'][0]['geometry']['location']['lat']
      long = gmaps['results'][0]['geometry']['location']['lng']

      doc = Nokogiri::XML(HTTParty.get('http://www.capitalbikeshare.com/data/stations/bikeStations.xml').body)

      # Sort stations by distance
      stations = doc.css('station').sort { |a,b| distance([lat, long], [a.at('lat').text.to_f, a.at('long').text.to_f]) <=> distance([lat, long], [b.at('lat').text.to_f, b.at('long').text.to_f]) }
      # Get the first one that has > 0 bikes
      station = stations.find { |s| s.at('nbBikes').text.to_i > 0 }

      build_response(lat, long, station)
    else
      { text: 'Sorry, I don’t understand that address.', response_type: 'ephemeral' }
    end
    response
  end

  def build_response(lat, long, station)
    name = station.at('name').text
    bikes = station.at('nbBikes').text
    docks = station.at('nbEmptyDocks').text
    station_lat = station.at('lat').text
    station_long = station.at('long').text
    last_updated = station.at('latestUpdateTime').text.to_i
    link = "https://maps.google.com?saddr=#{lat},#{long}&daddr=#{station_lat},#{station_long}&dirflg=w"

    attachments = []
    attachment = { fallback: "The nearest Capital Bikeshare station with bikes is #{name}: #{link}", color: '#ff300b', pretext: "This is the nearest Capital Bikeshare station with bikes:", title: name, title_link: link, image_url: map_image(station_lat, station_long) }
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

  def map_image(lat, long)
    "https://maps.googleapis.com/maps/api/staticmap?key=#{ENV['MAPS_API_KEY']}&size=400x200&markers=#{lat},#{long}&scale=2"
  end

  def get_access_token(code)
    response = HTTParty.get("https://slack.com/api/oauth.access?code=#{code}&client_id=#{ENV['CABI_CLIENT_ID']}&client_secret=#{ENV['CABI_CLIENT_SECRET']}&redirect_uri=#{cabi_auth_url}")
    JSON.parse(response.body)
  end
end
