class Untappd
  include ActiveSupport::Inflector

  def search(query)
    results = search_untappd(query)
    if results['response']['beers']['count'] == 0
      { text: 'That beer could not be found.', response_type: 'ephemeral' }
    elsif results['response']['beers']['count'] > 5
      { text: 'Too many results. Try narrowing your search.', response_type: 'ephemeral'}
    else
      title = ""
      if results['response']['beers']['count'] > 1
        title = "Showing first result of #{results['response']['beers']['count']}\n"
      end

      title = "#{title} #{results['response']['beers']['items'][0]['beer']['beer_name']}"
      title_link = "https://untappd.com/b/#{results['response']['beers']['items'][0]['beer']['beer_slug']}/#{results['response']['beers']['items'][0]['beer']['bid']}"
      description = results['response']['beers']['items'][0]['beer']['beer_description']
      image = results['response']['beers']['items'][0]['beer']['beer_label']

      {
        response_type: 'in_channel',
        attachments: [
          {
            title: title,
            title_link: title_link,
            thumb_url: image,
            text: description
          }
        ]
      }
    end
  end

  def search_untappd(query)
    response = Rails.cache.fetch("untappd:#{parameterize(query)}", expires_in: 24.hours) do
      HTTParty.get("https://api.untappd.com/v4/search/beer?client_secret=#{ENV['UNTAPPD_CLIENT_SECRET']}&client_id=#{ENV['UNTAPPD_CLIENT_ID']}&q=#{URI.escape(query)}").body
    end
    JSON.parse(response)
  end
end
