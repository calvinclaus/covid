json.(prospect_pool, :id, :name, :frontend_id, :errors)
if prospect_pool.frontend_id.present?
  json.frontend_id prospect_pool.frontend_id
else
  json.frontend_id prospect_pool.id
end
