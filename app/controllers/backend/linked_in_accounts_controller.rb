module Backend
  class LinkedInAccountsController < Backend::BackendController
    before_action :require_unlocked_admin!

    def index
      @linked_in_accounts = LinkedInAccount.all.order('name desc')
    end

    def new
      @linked_in_account = LinkedInAccount.new
    end

    def edit
      @linked_in_account = LinkedInAccount.find(params[:id])
    end

    def update
      @linked_in_account = LinkedInAccount.find(params[:id])
      if @linked_in_account.update(linked_in_account_params)
        flash[:alert] = ""
        flash[:notice] = "Passt, nehma!"
      else
        flash[:notice] = ""
        flash[:alert] = "Des is a Bledsinn, oida!"
      end
      render "backend/linked_in_accounts/edit"
    end

    def create
      @linked_in_account = LinkedInAccount.create(linked_in_account_params)
      if @linked_in_account.errors.present?
        flash[:notice] = ""
        flash[:alert] = "Des is a Bledsinn, oida!"
        render :new and return
      else
        flash[:alert] = ""
        flash[:notice] = "Passt, nehma!"
        redirect_to edit_backend_linked_in_account_path(@linked_in_account)
      end
    end

    def destroy
      @linked_in_account = LinkedInAccount.find(params[:id])
      @linked_in_account.destroy!
      flash[:notice] = "LinkedIn Account successfully deleted."
      redirect_to backend_linked_in_accounts_path
    end

    private

    def linked_in_account_params
      params.require(:linked_in_account).permit(
        :name,
        :email,
        :password,
        :li_at,
      )
    end
  end
end
