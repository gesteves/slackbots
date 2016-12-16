class GoogleMaps
  include ActiveSupport::Inflector

  def image(lat, long)
    "https://maps.googleapis.com/maps/api/staticmap?key=#{ENV['MAPS_API_KEY']}&size=400x200&markers=#{lat},#{long}&scale=2"
  end

  def location(location)
    Rails.cache.fetch("google_maps:v2:#{parameterize(location)}", expires_in: 30.days) do
      HTTParty.get("https://maps.googleapis.com/maps/api/geocode/json?address=#{URI::encode(location)}&key=#{ENV['MAPS_API_KEY']}").body
    end
  end
end
