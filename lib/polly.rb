class Polly
  def speak(params)
    text = params[:text].strip
    polly = synthesize_speech(text)
    s3_url = upload_to_s3(polly.audio_stream, params[:team_id], params[:channel_id])
    { text: "<#{s3_url}|#{text}>", response_type: 'in_channel', link_names: 1, unfurl_links: true, unfurl_media: true }
  end

  private
  def synthesize_speech(t)
    text = t.gsub(/_(.+)_/, '<emphasis>\1</emphasis>')
            .gsub(/\*(.+)\*/, '<emphasis level="strong">\1</emphasis>')
            .gsub(/~(.+)~/, '<prosody volume="x-soft">\1</prosody>')
    ssml = "<speak>#{text}</speak>"
    client = Aws::Polly::Client.new(credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY'], ENV['AWS_SECRET_KEY']), region: 'us-east-1')
    client.synthesize_speech(output_format: 'mp3', text: ssml, text_type: 'ssml', voice_id: ENV['POLLY_VOICE'], lexicon_names: ['lexicon'])
  end

  def upload_to_s3(audio_stream, team_id, channel_id)
    client = Aws::S3::Client.new(access_key_id: ENV['AWS_ACCESS_KEY'], secret_access_key: ENV['AWS_SECRET_KEY'], region: 'us-east-1')
    s3 = Aws::S3::Resource.new(client: client)
    obj = s3.bucket(ENV['S3_BUCKET']).object("#{team_id}/#{channel_id}/#{Digest::MD5.hexdigest(Time.now.to_i.to_s)}.mp3")
    obj.put({ body: audio_stream, acl: 'public-read' })
    obj.public_url
  end
end
