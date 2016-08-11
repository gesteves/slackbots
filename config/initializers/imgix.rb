::Ix = Imgix::Client.new(hosts: ENV['IMGIX_DOMAIN'].split(','), secure_url_token: ENV['IMGIX_TOKEN'], include_library_param: false, use_https: true)
