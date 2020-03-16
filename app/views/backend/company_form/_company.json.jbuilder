json.(@company, :id, :name, :errors, :prospect_pools, :prospect_distribution_status, :num_prospects_without_search, :total_credits)
json.used_credits @company.used_credits_cache
json.campaigns @company.campaigns, partial: 'backend/company_form/campaign', as: :campaign
json.credit_bookings @company.credit_bookings.sort_by(&:booking_date), partial: 'backend/company_form/credit_booking', as: :credit_booking


json.searches do
  json.cache_collection! @company.searches do |search|
    json.partial! partial: 'backend/company_form/search', search: search
  end
end


json.patch_url backend_update_company_form_url(id: @company.id)
json.show_url backend_show_company_form_url(id: @company.id)
json.blacklist_imports @company.blacklist_imports, partial: 'backend/company_form/blacklist_import', as: :blacklist_import
json.prospect_pools @company.prospect_pools, partial: 'backend/company_form/prospect_pool', as: :prospect_pool
json.gendered_salutes MessageUtils::GENDERED_SALUTES
json.campaign_stati Campaign::STATI
