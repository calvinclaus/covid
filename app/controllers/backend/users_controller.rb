module Backend
  class UsersController < Backend::BackendController
    before_action :require_unlocked_admin!

    def index
      @users = User.all.order(:name)
    end

    def show
      @user = User.find(params[:id])
      render "backend/users/edit"
    end

    def edit
      @user = User.find(params[:id])
    end

    def update
      @user = User.find(params[:id])
      if @user.update(user_params)
        flash[:alert] = ""
        flash[:notice] = "Passt, nehma!"
      else
        flash[:notice] = ""
        flash[:alert] = "Des is a Bledsinn, oida!"
      end
      render "backend/users/edit"
    end

    def send_set_password_email
      @user = User.find(params[:id])
      @user.creating_password = true
      @user.send_reset_password_instructions
      flash[:notice] = "Dem Nutzer wurde eine Email mit Anweisungen zum setzen des Passworts an #{@user.email} geschickt."
      redirect_to edit_backend_user_path(@user)
    end

    def new
      @user = User.new
    end

    def create
      @user = User.create(user_params.merge(password: Devise.friendly_token))
      if @user.errors.present?
        flash[:notice] = ""
        flash[:alert] = "Des is a Bledsinn, oida!"
        render :new and return
      else
        flash[:alert] = ""
        flash[:notice] = "Passt, nehma!"
        redirect_to edit_backend_user_path(@user)
      end
    end

    def log_in_as
      @user = User.find(params[:id])
      sign_in(:user, @user)
      redirect_to frontend_root_path
    end

    private

    def user_params
      params.require(:user).permit(
        :name,
        :email,
        :company_id,
        :can_see_campaign_details,
        :can_see_campaign_color_code,
        company_attributes: %i[id name],
      )
    end
  end
end
