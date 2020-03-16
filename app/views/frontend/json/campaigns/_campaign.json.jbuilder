json.cache! ['full', campaign] do
  json.partial! 'frontend/json/campaigns/campaign_lightweight', campaign: campaign

  json.segmented_statistics campaign.segmented_statistics, partial: 'frontend/json/campaigns/statistic', as: :statistic
  json.monthly_statistics campaign.monthly_statistics, partial: 'frontend/json/campaigns/statistic', as: :statistic
  json.weekly_statistics campaign.weekly_statistics, partial: 'frontend/json/campaigns/statistic', as: :statistic
  json.daily_statistics campaign.daily_statistics, partial: 'frontend/json/campaigns/statistic', as: :statistic
  json.query_statistics campaign.query_statistics, partial: 'frontend/json/campaigns/statistic', as: :statistic
  json.search_statistics campaign.search_statistics, partial: 'frontend/json/campaigns/statistic', as: :statistic
end
