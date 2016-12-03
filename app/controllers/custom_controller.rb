class CustomController < ApplicationController
  def happyhour
    replies = [
      "It’s happy hour! Come to the kitchen for drinks and to mingle and catch up with your coworkers."
    ]
    response = { text: replies.sample, response_type: 'in_channel' }
    HTTParty.post(params[:response_url], body: response.to_json)
    render text: '', status: 200
  end
end
