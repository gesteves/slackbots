class Untappd
  include ActiveSupport::Inflector

  def search(query)
    results = search_untappd(query)
    if results['response']['beers']['count'] == 0
      { text: 'I couldn’t find that beer!', response_type: 'ephemeral' }
    else
      result = results['response']['beers']['items'][0]
      title = result['beer']['beer_name']
      title_link = "https://untappd.com/b/#{result['beer']['beer_slug']}/#{result['beer']['bid']}"
      author_name = result['brewery']['brewery_name']
      author_link = "https://untappd.com/w/#{result['brewery']['brewery_slug']}/#{result['brewery']['brewery_id']}"
      description = result['beer']['beer_description']
      image = result['beer']['beer_label']
      ts = DateTime.parse(result['beer']['created_at']).to_i

      fields = []
      fields << { title: 'Style', value: result['beer']['beer_style'] } if result['beer']['beer_style'].present?
      fields << { title: 'ABV', value: "#{result['beer']['beer_abv']}% ABV", short: true } if result['beer']['beer_abv'].present?
      fields << { title: 'IBU', value: result['beer']['beer_ibu'], short: true } if result['beer']['beer_ibu'].present?

      {
        response_type: 'in_channel',
        attachments: [
          {
            author_name: author_name,
            author_link: author_link,
            color: '#FFCC4D',
            title: title,
            title_link: title_link,
            thumb_url: image,
            text: description,
            fields: fields,
            footer: 'Added',
            ts: ts
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
