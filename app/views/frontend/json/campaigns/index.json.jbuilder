json.cache_collection! @campaigns do |campaign|
  json.partial! partial: 'frontend/json/campaigns/campaign_lightweight', campaign: campaign
end
