module Backend
  class DashboardController < Backend::BackendController
    before_action :authenticate_admin!
    def show
      if current_admin.unlocked?
        redirect_to backend_campaigns_path
      end
    end

    def test_exception
      raise "Fooooobar"
    end
  end
end
