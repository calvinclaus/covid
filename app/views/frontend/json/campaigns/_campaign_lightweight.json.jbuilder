json.cache! ['light', campaign] do
  json.(campaign, :id, :name, :status, :target_audience_size, :next_milestone, :num_delivered, :num_accepted, :num_not_accepted, :num_accepted_not_answered, :num_answered, :num_replied_after_stage, :num_delivered, :created_at, :updated_at, :linked_in_account_name)
end
