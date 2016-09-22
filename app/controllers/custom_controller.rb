class CustomController < ApplicationController
  def happyhour
    response = { text: "It’s happy hour! Come to the kitchen for drinks and to mingle and catch up with your coworkers.", response_type: 'in_channel' }
    render json: response, status: 200
  end
end
