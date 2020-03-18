class UsersController < ApplicationController
  skip_before_action :verify_authenticity_token
  def create
    if User.where(email: params[:email].strip).first.present?
      user = User.where(email: params[:email].strip).first
      user.update!(subscribed: true)
      render json: "ok", status: 200 and return
    end

    @user = User.create(email: params[:email].strip)
    if @user.errors.present?
      render json: "error", status: 400 and return
    else
      render json: "ok", status: 200 and return
    end
  end

  def unsubscribe
    User.find(params[:id]).update!(subscribed: false)
    render json: "Erfolg!", status: 200 and return
  end
end
