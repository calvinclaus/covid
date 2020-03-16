json.(search, :id, :name, :notes, :search_result_csv_url, :num_contacted_prospects, :num_prospects, :num_blacklisted_prospects, :num_left_prospects, :queries, :linked_in_account_id, :linked_in_search_url, :status, :uses_csv_import, :errors, :linked_in_result_limit, :should_clear, :num_delivered, :num_accepted, :num_not_accepted, :num_accepted_not_answered, :num_answered, :num_replied_after_stage, :num_connection_errors, :num_connection_errors_after_deadline_where_errors_count)

if search.frontend_id.present?
  json.frontend_id search.frontend_id
else
  json.frontend_id search.id
end
