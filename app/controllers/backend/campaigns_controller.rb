module Backend
  class CampaignsController < Backend::BackendController
    before_action :require_unlocked_admin!
    def index
      @campaigns = Campaign.order('created_at desc')
      @campaigns_json = render_to_string(template: 'frontend/json/campaigns/index.json.jbuilder', formats: 'json', layout: false)
      render :index, formats: [:html]
    end

    def new
      @campaign = Campaign.new
      @campaign.company = Company.find(params[:company_id]) if params[:company_id].present?
      @campaign.name = params[:user_name] + " LLG" if params[:user_name].present?
    end

    def show
      if params[:format] == "json"
        @campaign = Campaign.find(params[:id])
        render "frontend/json/campaigns/campaign.json.jbuilder"
      else
        # frontend will take care of routing and requesting campaign details
        index
      end
    end

    def edit
      @campaign = Campaign.find(params[:id])
      redirect_to backend_company_path(@campaign.company_id)
    end

    def update
      @campaign = Campaign.find(params[:id])
      if @campaign.update(campaign_params)
        flash[:alert] = ""
        flash[:notice] = "Passt, nehma!"
      else
        flash[:notice] = ""
        flash[:alert] = "Des is a Bledsinn, oida!"
      end
      render "backend/campaigns/edit"
    end

    def create
      @campaign = Campaign.create(campaign_params)
      if @campaign.errors.present?
        flash[:notice] = ""
        flash[:alert] = "Des is a Bledsinn, oida!"
        render :new and return
      else
        flash[:alert] = ""
        flash[:notice] = "Passt, nehma!"
        redirect_to edit_backend_campaign_path(@campaign)
      end
    end

    def export
      @campaign = Campaign.find(params[:id])

      header = ["profileUrl", "name", "emailFromLinkedIn", "phoneFromLinkedIn", "companyName", "companyUrl", "title", "location", "vmid", "query", "message", "timestamp", "threadUrl", "acceptedRequestTimestamp", "followUp1Timestamp", "followUp1Message", "followUp2Timestamp", "followUp2Message", "followUp3Timestamp", "followUp3Message", "repliedAt", "repliedDuringStage"]

      assocs = @campaign.prospect_campaign_associations.
        used.
        left_joins(prospect: :prospect_search_associations).
        includes(:prospect, :linked_in_outreaches).
        includes(prospect: :prospect_search_associations).
        left_outer_joins(prospect: :linked_in_profile_scraper_results).
        includes(prospect: :linked_in_profile_scraper_results).
        where("linked_in_profile_scraper_results.id = (select max(my_lipsr.id) from linked_in_profile_scraper_results my_lipsr where my_lipsr.prospect_id = prospects.id) OR linked_in_profile_scraper_results.id IS NULL").
        order('"linked_in_outreaches"."sent_connection_request_at"')

      rows = assocs.map do |assoc|
        outreach = assoc.linked_in_outreaches.first
        res = [
          assoc.prospect.linked_in_profile_url,
          assoc.prospect.name,
          assoc.prospect.linked_in_profile_scraper_results.first&.email,
          assoc.prospect.linked_in_profile_scraper_results.first&.phone,
          assoc.prospect.primary_company_name,
          assoc.prospect.primary_company_linkedin_url,
          assoc.prospect.title,
          assoc.prospect.location,
          assoc.prospect.vmid,
          assoc.prospect.prospect_search_associations&.first&.through_query,
          outreach.connection_message,
          outreach.sent_connection_request_at,
          outreach.thread_url,
          outreach.accepted_connection_request_at,
        ]
        (0..2).each_with_index do |_m, i|
          if outreach.follow_up_messages[i].present?
            res.push(outreach.follow_up_messages[i]["sent_timestamp"])
            res.push(outreach.follow_up_messages[i]["message"])
          else
            res.push(nil)
            res.push(nil)
          end
        end


        res.push(outreach.replied_at)
        res.push(outreach.follow_up_stage_at_time_of_reply)
        res
      end
      csv_string = [header].concat(rows).inject([]){ |csv, row| csv << CSV.generate_line(row) }.join("")
      file = Tempfile.new("results-for-#{@campaign.id}")
      file.write(csv_string)
      file.close
      send_file file.path, filename: "results-#{@campaign.name.gsub(' ', '-')}.csv", type: "text/csv; charset=utf-8"
    end

    private

    def campaign_params
      params.require(:campaign).permit(
        :name,
        :next_milestone,
        :status,
        :notes,
        :started_at,
        :target_audience_size,
        :phantombuster_agent_id,
        :linked_in_account_id,
        :company_id,
        linked_in_account_attributes: %i[id name email li_at],
        segments: %i[date name],
      )
    end
  end
end
