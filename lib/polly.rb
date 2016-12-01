class Polly
  def speak(text)
    signer = Aws::Polly::Presigner.new(credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY'], ENV['AWS_SECRET_KEY']), region: 'us-east-1')
    url = signer.synthesize_speech_presigned_url(output_format: 'mp3', text: text, voice_id: 'Brian')
    { text: "<#{url}|#{text}>", response_type: 'in_channel', link_names: 1, unfurl_links: true }
  end
end
