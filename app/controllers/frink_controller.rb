class FrinkController < ApplicationController
  include ActionView::Helpers::TextHelper
  
  def index
    @page_title = '/frink: Simpsons gifs in Slack'
  end

  def slash
    if params[:token] == ENV['FRINK_VERIFICATION_TOKEN'] || Rails.env.development?
      query = params[:text].strip
      if query == '' || query == 'help'
        response = { text: "D'oh! You have to enter a quote from The Simpsons, like `#{params[:command]} everything's comin' up Milhouse!`", response_type: 'ephemeral' }
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

  def search(query)
    response = HTTParty.get("https://frinkiac.com/api/search?q=#{URI.escape(query)}")
    results = JSON.parse(response.body)
    if results.size == 0
      text = "D'oh! No results found for that quote."
      response_type = 'ephemeral'
    else
      best_match = results.first
      episode = best_match['Episode']
      timestamp = best_match['Timestamp']
      image, subtitle = screencap(query, episode, timestamp)
      text = "<#{image}|#{subtitle}>"
      response_type = 'in_channel'
    end
    { text: text, response_type: response_type, link_names: 1 }
  end

  def screencap(query, episode, timestamp)
    response = HTTParty.get("https://frinkiac.com/api/caption?e=#{episode}&t=#{timestamp}")
    body = JSON.parse(response.body)
    episode = body['Frame']['Episode']
    timestamp = body['Frame']['Timestamp'].to_i
    subtitle = closest_subtitle(query, body['Subtitles'])
    image = "https://frinkiac.com/gif/#{episode}/#{timestamp - 1000}/#{timestamp + 1000}.gif?lines=#{URI.escape(word_wrap(subtitle, line_width: 25))}"
    return image, subtitle
  end

  def closest_subtitle(text, subtitles)
    white = Text::WhiteSimilarity.new
    subtitles.max { |a, b| white.similarity(a['Content'], text) <=> white.similarity(b['Content'], text) }['Content']
  end

  def get_access_token(code)
  response = HTTParty.get("https://slack.com/api/oauth.access?code=#{code}&client_id=#{ENV['FRINK_CLIENT_ID']}&client_secret=#{ENV['FRINK_CLIENT_SECRET']}&redirect_uri=#{frink_auth_url}")
  JSON.parse(response.body)
end

end
