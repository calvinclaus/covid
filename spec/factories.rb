FactoryBot.define do
  factory :unlocked_admin, class: Admin do
    email{ "unlocked@admin.com" }
    password{ "dev1234" }
    unlocked{ true }
  end

  factory :company do
    name{ "Peter Co." }
    prospect_distribution_status{ "DONE" }
  end

  factory :company_with_prospect_pool, class: Company do
    name{ "Peter Co." }
    after :create do |company|
      create_list :prospect_pool, 1, company: company
      company.reload
    end
  end

  factory :prospect_pool do
    name{ "Default Prospect Pool" }
  end

  factory :company_with_blacklist, class: Company do
    name{ "Peter Co." }
    after :create do |company|
      create_list :blacklisted_company, 3, company: company
      company.reload
    end
  end

  factory :blacklisted_company do
    company_names = ["Media Shop GmbH", "Another On Blacklist"]
    sequence(:name){ |n| company_names[n - 1].present? ? company_names[n - 1] : "company-#{n}" }
  end



  factory :user do
    sequence(:email){ |n| "user#{n}@example.com" }
    password{ "dev1234" }
    name{ "Peter User" }
    company
  end

  factory :linked_in_account do
    name{ "Peter Pan" }
    li_at{ ENV['TEST_LI_AT'] }
  end

  factory :logged_out_linked_in_account, class: LinkedInAccount do
    name{ "Peter LoggedOut" }
    li_at{ ENV['LOGGED_OUT_LI_AT'] }
  end

  factory :campaign do
    name{ "Campaign Name" }
    notes{ "Some\nNotes" }
    phantombuster_agent_id{ "144053" }
    linked_in_account
    company
  end

  factory :linked_in_profile_scraper do
    campaign
  end

  factory :campaign_belonging_to_prospect_pool, class: Campaign do
    name{ "Campaign Name" }
    notes{ "Some\nNotes" }
    phantombuster_agent_id{ "144053" }
    linked_in_account
    company
    after :create do |campaign|
      create_list :prospect_pool_campaign_association, 1, prospect_pool: campaign.reload.company.prospect_pools.first, campaign: campaign
      campaign.reload
    end
  end

  factory :prospect_pool_campaign_association do
    prospect_pool
    campaign
  end

  factory :search do
    name{ "Some Search" }
    notes{ "Some\nNotes" }
    search_result_csv_url{ "https://phantombuster.s3.amazonaws.com/userAws/awsfoldertest/some-search.csv" }
    company
  end
end
