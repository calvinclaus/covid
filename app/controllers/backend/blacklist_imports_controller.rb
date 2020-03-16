module Backend
  class BlacklistImportsController < Backend::BackendController
    before_action :require_unlocked_admin!

    def create
      @blacklist_import = BlacklistImport.create(blacklist_import_params)
      if @blacklist_import.errors.present?
        flash[:notice] = ""
        flash[:alert] = "Des is a Bledsinn, oida!"
        @company = @blacklist_import.company

        # TODO DRY: companies_controller
        @campaigns = @company.campaigns.all.order('created_at desc')
        @campaigns_json = render_to_string(template: 'frontend/json/campaigns/index.json.jbuilder', formats: 'json', layout: false)
        render "backend/companies/show", formats: [:html]

      else
        flash[:alert] = ""
        flash[:notice] = "Passt, nehma!"
        redirect_to backend_company_path(@blacklist_import.company)
      end
    end

    private

    def blacklist_import_params
      params.require(:blacklist_import).permit(
        :csv_url,
        :company_id,
      )
    end
  end
end
