json.company do
  json.partial!('backend/company_form/company', company: @company)
end
