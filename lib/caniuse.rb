class Caniuse
  include ActionView::Helpers::NumberHelper

  def search(query)
    caniuse_data = JSON.parse(get_caniuse_data)
    features = caniuse_data['data']
    matched_feature = features.find { |k, h| k == query || h['title'].downcase == query }
    if matched_feature.present?
      feature = features[matched_feature.first]
      build_response(query, feature)
    else
      white = Text::WhiteSimilarity.new
      matched_features = features.select { |k, h| white.similarity(query, k) > 0.5 || white.similarity(query, h["title"].downcase) > 0.5 }
      if matched_features.size == 0
        { text: "Sorry, I couldn’t find data for `#{query}`!", response_type: 'ephemeral' }
      elsif matched_features.size == 1
        matched_feature = matched_features.first
        feature = features[matched_feature.first]
        build_response(feature)
      else
        { text: "Sorry, I couldn’t find data for `#{query}`. Did you mean one of these? #{matched_features.collect { |f| "`#{f.first}`" }.join(', ') }", response_type: 'ephemeral' }
      end
    end

  end

  private

  def build_response(key, feature)
    attachments = []
    attachment = { title: feature['title'],
                   title_link: "http://caniuse.com/#search=#{key}",
                   fallback: "#{feature['title']} (http://caniuse.com/#search=#{key}): #{feature['description']}",
                   text: feature['description'],
                   color: get_color(feature),
                   mrkdwn_in: ['text', 'title', 'fields', 'fallback'] }
    fields = []
    fields << { title: 'Full support', value: number_to_percentage(feature['usage_perc_y'], precision: 2), short: true }
    fields << { title: 'Partial support', value: number_to_percentage(feature['usage_perc_a'], precision: 2), short: true }
    if feature['spec'].present? && feature['status'].present?
      fields << { title: 'Spec', value: "<#{feature['spec']}|#{get_status_name(feature['status'])}>" }
    end
    if feature['links'].present?
      fields << { title: 'Links & resources', value: feature['links'].map { |l| "<#{l['url']}|#{l['title']}>" }.join("\n") }
    end
    attachment[:fields] = fields
    attachments << attachment
    { response_type: 'in_channel', attachments: attachments }
  end

  def get_color(feature)
    full_support = feature['usage_perc_y'].to_f
    if full_support >= 90
      'good'
    elsif full_support >= 50
      'warning'
    else
      'danger'
    end
  end

  def get_status_name(code)
    Rails.cache.fetch("caniuse:status_names", expires_in: 24.hours) do
      caniuse_data = JSON.parse(get_caniuse_data)
      caniuse_data['statuses'][code]
    end
  end

  def get_caniuse_data
    Rails.cache.fetch("caniuse:data", expires_in: 24.hours) do
      HTTParty.get('https://raw.githubusercontent.com/Fyrd/caniuse/master/data.json').body
    end
  end
end
