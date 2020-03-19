class UsersController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate, only: [:count]
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


  ADMINS = %w(motion:Augustholler11)
  def count
    render json: User.where(subscribed: true).size, status: 200 and return
  end

  def authenticate
    if user = authenticate_with_http_basic { |user, pwd| ADMINS.include?([user, pwd].join(':')) ? user : nil }
      @current_admin = user
    else
      request_http_basic_authentication
    end
  end
end
