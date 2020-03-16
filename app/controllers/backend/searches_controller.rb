module Backend
  class SearchesController < Backend::BackendController
    before_action :require_unlocked_admin!

    def show
      @search = Search.find(params[:id])
      @search_data = render_to_string(template: '/backend/searches/show.json.jbuilder', formats: 'json', layout: false)
      render :show, formats: [:html]
    end

    def start_linked_in_company_domain_finder
      @search = Search.find(params[:id])
      raise "Not Present" unless @search.linked_in_company_domain_finder.present?

      @search.linked_in_company_domain_finder.update!(status: "STARTING")
      LinkedInCompanyDomainFinder::FindDomains.perform_later(@search.linked_in_company_domain_finder)
      flash[:notice] = "Scheduling successfull. LinkedIn Company Domain Finder will start soon!"
      redirect_to backend_search_path(@search)
    end

    def stop_linked_in_company_domain_finder
      @search = Search.find(params[:id])
      raise "Not Present" unless @search.linked_in_company_domain_finder.present?

      @search.linked_in_company_domain_finder.update!(status: "STOPPING")
      flash[:notice] = "LinkedIn Company Domain Finder stopping in the next minutes..."
      redirect_to backend_search_path(@search)
    end

    private

    def search_params
      params.require(:search).permit(
        :name,
        :notes,
        :search_result_csv_url,
        :company_id,
        linked_in_company_domain_finder_attributes: [:id, linked_in_account_ids: []],
      )
    end
  end
end
