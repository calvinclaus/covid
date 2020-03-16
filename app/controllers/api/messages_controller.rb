module Api
  class MessagesController < Api::ApiController
    skip_before_action :verify_authenticity_token
    def populate_message
      message = MessageUtils.populate_message(
        params[:message], params[:data].to_unsafe_h, gender_country: params[:gender_country]
      )
      render(json: {
               message: message,
               char_count: message.size,
             }, status: 200)
    rescue GenderNotFound => e
      render(json: {message: nil, error: e.gender_data}, status: 404)
    end
  end
end
