module Backend
  class AdminsController < Backend::BackendController
    before_action :require_unlocked_admin!

    def show
      @admins = Admin.all
    end

    def edit
      @admin = Admin.find(params[:id])
    end

    def update
      @admin = Admin.find(params[:format])
      if @admin == current_admin && admin_params[:unlocked] != "1"
        flash[:alert] = "You cannot lock your own profile."
        render "backend/admins/edit" and return
      end
      flash[:alert] = ""
      flash[:notice] = "Changes saved successfully."
      @admin.update(admin_params)
      render "backend/admins/edit" and return
    end

    def delete
      @admin = Admin.find(params[:id])
      if current_admin == @admin
        flash[:alert] = "You cannot delete your own profile."
        redirect_to show_admins_path and return
      end
      if @admin.destroy
        flash[:notice] = "Admin successfully deleted."
      else
        flash[:alert] = "Admin could not be deleted. Contact support."
      end
      redirect_to show_admins_path and return
    end

    def admin_params
      params.require(:admin).permit(
        :unlocked,
      )
    end
  end
end
