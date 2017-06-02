json.version '1.0'
json.response do
  if @forecast.nil?
    json.set! 'outputSpeech' do
      json.type 'PlainText'
      json.text "Sorry, I couldn't get your forecast."
    end
  else
    json.set! 'outputSpeech' do
      json.type 'SSML'
      json.ssml forecast_ssml(@forecast)
    end
    json.set! 'card' do
      if !@forecast['currently'].nil? && ['clear-day', 'clear-night', 'rain', 'snow', 'wind', 'fog', 'cloudy', 'partly-cloudy-day', 'partly-cloudy-night'].include?(@forecast['currently']['icon'])
        image_path = ActionController::Base.helpers.image_path("weather/#{@forecast['currently']['icon']}.png")
        big_url = Ix.path("https://#{ENV['HOST']}#{image_path}").to_url(w: 1200)
        small_url = Ix.path("https://#{ENV['HOST']}#{image_path}").to_url(w: 720)

        json.type 'Standard'
        json.title "Weather Forecast"
        json.text forecast_plain(@forecast)
        json.set! 'image' do
          json.set! 'smallImageUrl', small_url
          json.set! 'largeImageUrl', big_url
        end
      else
        json.type 'Simple'
        json.title "Weather Forecast"
        json.content forecast_plain(@forecast)
      end
    end
  end
end
