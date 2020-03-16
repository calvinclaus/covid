module Frontend::Json
  class CampaignsController < JsonController
    def index
      @campaigns = current_user.company.campaigns
    end

    def campaign
      @campaign = current_user.company.campaigns.find(params[:id])
    end
  end
end
