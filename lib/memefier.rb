class Memefier
  include ActionView::Helpers::TextHelper
  include ActiveSupport::Inflector

  def memefy(query)
    original_url = URI.extract(query).try(:first)
    text = query.gsub(original_url, '').strip unless original_url.nil?
    if original_url.nil?
      { text: 'You need to include an image to memefy!', response_type: 'ephemeral' }
    elsif !text.present?
      { text: 'You need to include a text for the image!', response_type: 'ephemeral' }
    else
      text_opts = {
        w: 600,
        txt64: text,
        txtfont64: 'Impact',
        txtclr: 'fff',
        txtlineclr: '000',
        txtsize: 60,
        txtline: 2,
        txtalign: 'center'
      }
      text_url = Ix.path('~text').to_url(text_opts)
      puts text_url
      opts = {
        w: 600,
        mark64: text_url,
        markalign: 'bottom,center'
      }
      url = Ix.path(original_url).to_url(opts)
      { text: "<#{url}|#{text}>", response_type: 'in_channel' }
    end
  end

  def palette(query)
    url = URI.extract(query).try(:first)
    if url.nil?
      { text: 'You need to include an image URL!', response_type: 'ephemeral' }
    else
      begin
        json = JSON.parse(HTTParty.get(Ix.path(url).to_url(palette: 'json')).body)
        palette_response(json)
      rescue
        { text: 'Uh oh, something went wrong!', response_type: 'ephemeral' }
      end
    end
  end

  private

  def palette_response(json)
    attachments = []
    attachment = { fallback: "Here’s the color palette: #{json['colors'].map { |c| c['hex']}.join(', ')}" }
    attachment[:color] = json['dominant_colors']['vibrant']['hex'] if json['dominant_colors']['vibrant'].present?
    fields = []
    fields << { title: 'Color Palette', value: json['colors'].map { |c| c['hex']}.join(', ') }

    json['dominant_colors'].each do |k, v|
      fields << { title: titleize(k), value: v['hex'], short: true }
    end

    attachment[:fields] = fields
    attachments << attachment
    { response_type: 'in_channel', attachments: attachments, text: 'Here’s the color palette & dominant colors for your image:', unfurl_links: true }
  end

end
