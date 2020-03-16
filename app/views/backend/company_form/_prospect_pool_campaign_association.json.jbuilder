json.(prospect_pool_campaign_association, :id, :prospect_pool_id)
if prospect_pool_campaign_association.frontend_id.present?
  json.frontend_id prospect_pool_campaign_association.frontend_id
else
  json.frontend_id prospect_pool_campaign_association.id
end
