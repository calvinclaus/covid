require_relative '../../../lib/company_name_equality/company_name_equality.rb'
module Api
  class CampaignsController < Api::ApiController
    def executed
      @campaign = Campaign.where(phantombuster_agent_id: params[:phantombuster_agent_id]).first

      render(json: "not found", status: 404) and return if @campaign.blank?

      linked_in_account = @campaign.linked_in_account
      linked_in_account.num_connections = params[:num_connections] if params[:num_connections].present?
      linked_in_account.account_type = params[:account_type] if params[:account_type].present?
      unless linked_in_account.logged_in?
        # an li_at change automatically sets the account to logged_in
        # if we are still logged out that means the li_at wasn't changed
        # but we are logged in. so we were never actually logged out
        # we correct for this by deleting the last logout
        linked_in_account.logouts.order(timestamp: :desc).first&.delete
      end
      linked_in_account.logged_in = true
      linked_in_account.save!

      @campaign.invocations.create!(timestamp: DateTime.current)

      none_scheduled = Delayed::Job.all.where('queue = ? and locked_at is null', 'fast_running').all? do |job|
        GlobalID::Locator.locate(job.payload_object.job_data["arguments"].first["_aj_globalid"]) != @campaign
      end
      if none_scheduled
        Campaign::PhantombusterSync.perform_later(@campaign)
      end

      render(json: "ok")
    end

    def logged_out
      @campaign = Campaign.where(phantombuster_agent_id: params[:phantombuster_agent_id]).first

      render(json: "not found", status: 404) and return if @campaign.blank?

      if @campaign.linked_in_account.logged_in?
        @campaign.linked_in_account.update!(logged_in: false)
        @campaign.linked_in_account.logouts.create!(timestamp: DateTime.current)
      end

      render(json: "ok")
    end

    def prime_campaign_cache
      @campaign = Campaign.find(params[:id])
      render 'frontend/json/campaigns/campaign.json.jbuilder', layout: false
    end

    def next_prospects_with_id
      @campaign = Campaign.find(params[:id])
      next_prospects_with_campaign
    end

    def next_prospects
      @campaign = Campaign.where(phantombuster_agent_id: params[:phantombuster_agent_id]).first
      next_prospects_with_campaign
    end

    def next_prospects_with_campaign
      raise "Currently locked" unless @campaign.company.prospect_distribution_status == "DONE"

      limit = params[:limit].blank? ? 30 : params[:limit]

      @prospects = @campaign.next_prospects(limit: limit)

      rows = @prospects.map do |prospect|
        clean_name = HumanNameUtils.clean_and_split_name(prospect.name)
        [
          prospect.linked_in_profile_url,
          prospect.name,
          clean_name.first + " " + clean_name.last,
          prospect.title,
          prospect.primary_company_name,
          prospect.primary_company_linkedin_url,
          prospect.id,
          prospect.prospect_search_associations&.first&.through_query,
        ]
      end
      csv_string = [["profileUrl", "name", "cleanName", "title", "companyName", "companyLinkedInUrl", "id", "query"]].concat(rows).inject([]){ |csv, row| csv << CSV.generate_line(row) }.join("")

      file = Tempfile.new("next-prospects-for-#{@campaign.id}")
      file.write(csv_string)
      file.close
      send_file file.path, filename: "next-prospects.csv", type: "text/csv; charset=utf-8"
    end

    def blacklist_has_one_of
      @campaign = Campaign.where(phantombuster_agent_id: params[:phantombuster_agent_id]).first

      render(json: "not found", status: 404) and return if @campaign.blank?

      blacklist = CompanyNameEquality.with_cleaned_company_names(@campaign.company.blacklisted_companies.pluck(:name))
      check_against = CompanyNameEquality.with_cleaned_company_names(params[:companies].present? ? params[:companies] : [])

      companies_on_blacklist = check_against.select do |company_to_check_if_on_blacklist|
        blacklist.any? do |blacklist_item|
          CompanyNameEquality.same_company?(
            blacklist_item[:clean_name],
            company_to_check_if_on_blacklist[:clean_name],
            cleaned: true
          )
        end
      end

      result = {
        response: companies_on_blacklist.present?,
        companies_on_blacklist: companies_on_blacklist.map{ |c| c[:name] },
      }

      render(json: result)
      GC.start
    end

    # rubocop:disable Naming/PredicateName
    def has_blacklist
      @campaign = Campaign.where(phantombuster_agent_id: params[:phantombuster_agent_id]).first

      render(json: "not found", status: 404) and return if @campaign.blank?

      result = {
        response: !@campaign.company.blacklisted_companies.empty?,
        size: @campaign.company.blacklisted_companies.size,
      }

      render(json: result)
    end
    # rubocop:enable Naming/PredicateName
  end
end
