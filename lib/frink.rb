class Frink
  include ActionView::Helpers::TextHelper
  include ActiveSupport::Inflector

  def search(query)
    results = search_frink(query)
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

  private

  def screencap(query, episode, timestamp)
    response = HTTParty.get("https://frinkiac.com/api/caption?e=#{episode}&t=#{timestamp}")
    body = JSON.parse(response.body)
    episode = body['Frame']['Episode']
    timestamp = body['Frame']['Timestamp'].to_i
    subtitle = closest_subtitle(query, body['Subtitles'])
    duration = (ENV['FRINK_GIF_DURATION'].to_i * 1000) / 2
    image = "https://frinkiac.com/gif/#{episode}/#{timestamp - duration}/#{timestamp + duration}.gif?lines=#{URI.escape(word_wrap(subtitle, line_width: 25))}"
    return image, subtitle
  end

  def closest_subtitle(text, subtitles)
    white = Text::WhiteSimilarity.new
    subtitles.max { |a, b| white.similarity(a['Content'], text) <=> white.similarity(b['Content'], text) }['Content']
  end

  def search_frink(query)
    response = Rails.cache.fetch("frink:#{parameterize(query)}", expires_in: 24.hours) do
      HTTParty.get("https://frinkiac.com/api/search?q=#{URI.escape(query)}").body
    end
    JSON.parse(response).reject { |e| e['Episode'] =~ /S1[^0]E\d+/ } # Reject results after season 10 DON'T @ ME
  end
end
