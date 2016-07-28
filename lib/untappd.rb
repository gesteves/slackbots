class Untappd
  include ActiveSupport::Inflector

  def search(query)
    results = search_untappd(query)
    if results['response']['beers']['count'] == 0
      { text: 'That beer could not be found.', response_type: 'ephemeral' }
    elsif results['response']['beers']['count'] > 5
      { text: 'Too many results. Try narrowing your search.', response_type: 'ephemeral'}
    else
      text = ""
      if results['response']['beers']['count'] > 1
        text = "Showing first result of #{results['response']['beers']['count']}\n"
      end

      text = "#{text} #{results['response']['beers']['items'][0]['beer']['beer_name']}"
      title_link = "https://untappd.com/b/#{results['response']['beers']['items'][0]['beer']['beer_slug']}/#{results['response']['beers']['items'][0]['beer']['bid']}"
      description = results['response']['beers']['items'][0]['beer']['beer_description']
      image = results['response']['beers']['items'][0]['beer']['beer_label']

      {
        response_type: 'in_channel',
        text: text,
        attachments: [
          {
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
      HTTParty.get("https://api.untappd.com/v4/search/beer?client_secret=B6FFE60D63EC62CB3981DBA35121F8C9B4FAB533&client_id=DF2A177AB979D0FA50B4C663D5FDF026FF391582&q=#{URI.escape(query)}").body
    end
    JSON.parse(response)
  end
end
