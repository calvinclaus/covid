json.(campaign, :id, :name, :notes, :phantombuster_agent_id, :created_at, :updated_at, :company_id, :status, :target_audience_size, :next_milestone, :num_delivered, :num_accepted, :linked_in_account_name, :linked_in_account_id, :num_not_accepted, :num_accepted_not_answered, :num_answered, :num_replied_after_stage, :num_delivered, :segments, :next_milestone, :status, :last_synced_at, :follow_up_stages_to_count_as_credit_use, :errors, :phantombuster_errors, :message, :manual_daily_request_target, :automatic_daily_request_target, :manual_people_count_to_keep, :manual_control, :automatic_people_count_to_keep, :should_save_to_phantombuster, :script_type, :num_prospects, :num_assigned_not_contacted_prospects, :num_blacklisted, :num_gender_unknown, :num_not_contacted_and_blacklisted, :num_connection_errors, :num_connection_errors_after_deadline_where_errors_count, :timezone)
json.follow_ups(campaign.follow_ups.map{ |f| {daysDelay: f["days_delay"], message: f["message"], errors: f["errors"]} })

unless campaign.linked_in_profile_scraper.present?
  campaign.linked_in_profile_scraper = LinkedInProfileScraper.new
end
json.linked_in_profile_scraper do
  json.(campaign.linked_in_profile_scraper, :id, :active, :daily_scraping_target, :errors)
end

if campaign.phantombuster_agent_id.present?
  json.next_prospects_url api_next_prospects_url(phantombuster_agent_id: campaign.phantombuster_agent_id, key: ENV['OUR_API_KEY'])
end
if campaign.id.present?
  json.export_url backend_export_campaign_url(campaign.id)
end
if campaign.frontend_id.present?
  json.frontend_id campaign.frontend_id
else
  json.frontend_id campaign.id
end
json.campaign_search_associations do
  json.partial! "backend/company_form/campaign_search_association", collection: campaign.campaign_search_associations, as: :campaign_search_association
end
json.prospect_pool_campaign_associations do
  json.partial! "backend/company_form/prospect_pool_campaign_association", collection: campaign.prospect_pool_campaign_associations, as: :prospect_pool_campaign_association
end
