module Frontend
  class SearchesController < Frontend::FrontendController
    before_action :authenticate_user!

    def show
      @search = current_user.company.searches.find(params[:id])
      @search_data = render_to_string(template: '/backend/searches/show.json.jbuilder', formats: 'json', layout: false)
      render :show, formats: [:html]
    end
  end
end
