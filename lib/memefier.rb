class Memefier
  include ActionView::Helpers::TextHelper
  include ActiveSupport::Inflector

  def memefy(query, opts = {})
    original_url = URI.extract(query, ['http', 'https']).try(:first)
    text = query.gsub(original_url, '').strip unless original_url.nil?
    if original_url.nil?
      { text: 'You need to include an image to memefy!', response_type: 'ephemeral' }
    elsif !text.present?
      { text: 'You need to include a text for the image!', response_type: 'ephemeral' }
    else
      text_opts = {
        w: 1000,
        txt64: emojify(text),
        txtfont64: 'Impact',
        txtclr: 'fff',
        txtlineclr: '000',
        txtsize: text_size(emojify(text)),
        txtline: 2,
        txtalign: 'center'
      }
      text_url = Ix.path('~text').to_url(text_opts)
      puts text_url
      opts = {
        w: 1000,
        mark64: text_url,
        markalign: 'bottom,center',
        fm: 'jpg'
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

  def text_size(text)
    case text.size
    when 0..100
      80
    when 101..200
      60
    else
      40
    end
  end

  def emojify(text)
    text.gsub(/:([\w-]+):/) { |e| Emoji.find_by_alias($1).present? ? Emoji.find_by_alias($1).raw : '' }
  end

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
