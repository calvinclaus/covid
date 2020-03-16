require_relative '../../../lib/company_name_equality/company_name_equality.rb'
module Backend
  class CompaniesController < Backend::BackendController
    before_action :require_unlocked_admin!

    def index
      @companies = Company.all.order('credits_left_cache asc')
    end

    def show
      @company = Company.includes(:prospect_pools, :searches, campaigns: %i[linked_in_account prospect_pool_campaign_associations campaign_search_associations]).find(params[:id])
      @linked_in_accounts = LinkedInAccount.all
      if @company.prospect_pools.blank?
        @company.prospect_pools.create!(name: "Default")
      end
      @campaigns = @company.campaigns
      @campaigns_json = render_to_string(template: 'frontend/json/campaigns/index.json.jbuilder', formats: 'json', layout: false)

      @company_form_data = render_to_string(template: 'backend/company_form/show.json.jbuilder', formats: 'json', layout: false)
      render :show, formats: [:html]
    end

    def new
      @company = Company.new
    end

    def edit
      @company = Company.find(params[:id])
    end

    def update
      @company = Company.find(params[:id])
      if @company.update(company_params)
        flash[:alert] = ""
        flash[:notice] = "Passt, nehma!"
      else
        flash[:notice] = ""
        flash[:alert] = "Des is a Bledsinn, oida!"
      end
      # pp @company.errors
    end

    def create
      @company = Company.create(company_params)
      if @company.errors.present?
        flash[:notice] = ""
        flash[:alert] = "Des is a Bledsinn, oida!"
        render :new and return
      else
        flash[:alert] = ""
        flash[:notice] = "Passt, nehma!"
        redirect_to edit_backend_company_path(@company)
      end
    end

    def prospects_after_blacklist
      @company = Company.find(params[:id])
      check_against = @company.prospects.pluck(:id, :primary_company_name).map{ |p|
        {
          id: p[0],
          name: p[1],
          clean_company_name: CompanyNameEquality.clean_name(p[1]),
        }
      }

      size_before = check_against.size

      blacklist = @company.blacklisted_companies.pluck(:name).map{ |n|
        {
          name: n,
          clean_company_name: CompanyNameEquality.clean_name(n),
        }
      }

      check_against = check_against.reject do |company_to_check_if_on_blacklist|
        blacklist.any? do |blacklist_item|
          res = CompanyNameEquality.same_company?(
            blacklist_item[:clean_company_name],
            company_to_check_if_on_blacklist[:clean_company_name],
            cleaned: true
          )
          if res
            pp "#{blacklist_item[:name]} == #{company_to_check_if_on_blacklist[:name]}"
          end
          res
        end
      end

      pp "size was #{size_before}, now excluded #{size_before - check_against.size}"

      non_blacklisted_prospects = @company.prospects.where(id: check_against.map{ |c| c[:id] }).order('created_at asc')

      header = ["linked_in_profile_url", "name", "primary_company_name", "linked_in_profile_url_from_search", "discovered_through_queries"]
      translated_header = ["profileUrl", "name", "companyName", "baseUrl", "query"]

      search_ids = @company.searches.pluck(:id)
      rows = non_blacklisted_prospects.map do |person|
        row = []
        header.each do |col|
          row[header.find_index(col)] = if col == "discovered_through_queries"
                                          person.prospect_search_associations.where(search_id: search_ids).first.through_query
                                        else
                                          person.public_send(col)
                                        end
        end
        row
      end
      csv_string = [translated_header].concat(rows).inject([]){ |csv, row| csv << CSV.generate_line(row) }.join("")


      file = Tempfile.new("email_guessing_task_result-#{rand(10000)}")
      file.write(csv_string)
      file.close
      send_file file.path, filename: "prospects-after-blacklist-for-company-#{@company.id}.csv", type: "text/csv; charset=utf-8"
    end


    private

    def company_params
      params.require(:company).permit(
        :id,
        :name,
        :reseller_id,
        searches_attributes: %i[
          id
          name
          notes
          search_result_csv_url
        ],
        campaigns_attributes: [
          :id,
          :name,
          :next_milestone,
          :status,
          :notes,
          :started_at,
          :target_audience_size,
          :phantombuster_agent_id,
          :linked_in_account_id,
          :company_id,
          :segments,
          {linked_in_account_attributes: %i[id name email li_at]},
          {prospect_pool_campaign_associations_attributes: %i[id prospect_pool_id]},
          {campaign_search_associations_attributes: %i[id search_id]},
        ],
        prospect_pools_attributes: %i[
          id
          name
        ],
        resold_company_ids: [],
      )
    end
  end
end
