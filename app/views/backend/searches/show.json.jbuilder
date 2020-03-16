json.(@search, :id, :name, :notes, :search_result_csv_url, :num_contacted_prospects, :num_prospects, :num_blacklisted_prospects, :num_left_prospects, :queries, :linked_in_account_id, :linked_in_search_url, :status, :uses_csv_import, :errors, :linked_in_result_limit, :should_clear, :num_delivered, :num_accepted, :num_not_accepted, :num_accepted_not_answered, :num_answered, :num_replied_after_stage)


json.monthly_statistics @search.monthly_statistics, partial: 'frontend/json/campaigns/statistic', as: :statistic
json.weekly_statistics @search.weekly_statistics, partial: 'frontend/json/campaigns/statistic', as: :statistic
json.daily_statistics @search.daily_statistics, partial: 'frontend/json/campaigns/statistic', as: :statistic
json.campaign_statistics @search.campaign_statistics, partial: 'frontend/json/campaigns/statistic', as: :statistic
json.query_statistics @search.query_statistics, partial: 'frontend/json/campaigns/statistic', as: :statistic
