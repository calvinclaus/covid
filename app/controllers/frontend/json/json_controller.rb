module Frontend::Json
  class JsonController < ApplicationController
    layout false
    before_action :authenticate_user!
    before_action :ensure_json_request

    def ensure_json_request
      return if request.format == :json

      render nothing: true, status: 406
    end
  end
end
