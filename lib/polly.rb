class Polly
  def speak(params)
    text = params[:text].strip
    url = generate_mp3_url(text)
    file = download_file(url)
    s3_url = upload_to_s3(file, params[:team_id], params[:channel_id])
    { text: "<#{s3_url}|#{text}>", response_type: 'in_channel', link_names: 1, unfurl_links: true }
  end

  private

  def generate_mp3_url(text)
    signer = Aws::Polly::Presigner.new(credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY'], ENV['AWS_SECRET_KEY']), region: 'us-east-1')
    signer.synthesize_speech_presigned_url(output_format: 'mp3', text: text, voice_id: ENV['POLLY_VOICE'])
  end

  def download_file(url)
    tmp = Tempfile.new([Time.now.to_i.to_s, '.mp3'])
    tmp.binmode
    tmp.write(HTTParty.get(url).body)
    tmp.flush
    File.new(tmp)
  end

  def upload_to_s3(file, team_id, channel_id)
    client = Aws::S3::Client.new(access_key_id: ENV['AWS_ACCESS_KEY'], secret_access_key: ENV['AWS_SECRET_KEY'], region: 'us-east-1')
    s3 = Aws::S3::Resource.new(client: client)
    obj = s3.bucket(ENV['S3_BUCKET']).object("#{team_id}/#{channel_id}/#{Digest::MD5.hexdigest(Time.now.to_i.to_s)}.mp3")
    obj.upload_file(file.path, { acl: 'public-read' })
    obj.public_url
  end
end
