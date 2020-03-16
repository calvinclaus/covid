json.(blacklist_import, :id, :csv_url, :status, :errors, :type, :num_blacklisted)
if blacklist_import.frontend_id.present?
  json.frontend_id blacklist_import.frontend_id
else
  json.frontend_id blacklist_import.id
end
