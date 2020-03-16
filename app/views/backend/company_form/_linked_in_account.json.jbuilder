json.(linked_in_account, :id, :name, :email, :li_at, :errors, :created_at)

if linked_in_account.frontend_id.present?
  json.frontend_id linked_in_account.frontend_id
else
  json.frontend_id linked_in_account.id
end
