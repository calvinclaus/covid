module Backend
  class BackendController < ApplicationController
    layout 'backend'
    before_action :authenticate_admin!

    skip_before_action :verify_authenticity_token, if: ->{ params[:format] == "json" }
    skip_before_action :verify_authenticity_token, if: ->{ request.format.json? }

    private

    def require_unlocked_admin!
      unless current_admin.unlocked?
        flash[:alert] = "Ask an admin to unlock your profile first."
        redirect_to "/backend" and return
      end
    end
  end
end
