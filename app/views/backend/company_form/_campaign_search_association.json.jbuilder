json.(campaign_search_association, :id, :search_id)
if campaign_search_association.frontend_id.present?
  json.frontend_id campaign_search_association.frontend_id
else
  json.frontend_id campaign_search_association.id
end
