class GoogleMaps
  include ActiveSupport::Inflector
  
  def image(lat, long)
    "https://maps.googleapis.com/maps/api/staticmap?key=#{ENV['MAPS_API_KEY']}&size=400x200&markers=#{lat},#{long}&scale=2"
  end

  def location(location)
    Rails.cache.fetch("google_maps:#{parameterize(location)}", expires_in: 24.hours) do
      HTTParty.get("http://maps.googleapis.com/maps/api/geocode/json?address=#{URI::encode(location)}&sensor=false").body
    end
  end
end
