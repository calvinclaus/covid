module Frontend
  class DashboardController < Frontend::FrontendController
    before_action :authenticate_user!
    def show
      @campaigns = current_user.company.campaigns_including_resold.order('created_at desc')
      @campaigns_json = render_to_string(template: 'frontend/json/campaigns/index.json.jbuilder', formats: 'json', layout: false)
      render :show, formats: [:html]
    end

    def campaign
      if params[:format] == "json"
        @campaign = current_user.company.campaigns_including_resold.find(params[:id])
        render "frontend/json/campaigns/campaign.json.jbuilder"
      else
        show
      end
    end
  end
end
