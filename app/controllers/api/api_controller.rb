module Api
  class ApiController < ApplicationController
    layout false
    before_action :authenticate!

    private

    def authenticate!
      return true if params[:key] == ENV['OUR_API_KEY'] || (current_admin.present? && current_admin.unlocked?)

      render(json: "not authenticated", status: 401) and return false
    end
  end
end
