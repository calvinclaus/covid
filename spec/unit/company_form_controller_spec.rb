require 'rails_helper'

RSpec.describe Backend::CompanyFormController, type: :controller do
  render_views
  it "can update a company and all its associated models" do
    # mock phantombuster api request
    stub_request(:post, "https://api.phantombuster.com/api/v2/agents/save").
      with(
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Content-Type' => 'application/json',
          'User-Agent' => 'Ruby',
          'X-Phantombuster-Key' => 'Y6VpQGeuDMf2AoPYSgURiUmuVeZd6aWL',
        }
      ).
      to_return(status: 200, body: '{"id": 8273271927}', headers: {})
    company = create(:company)
    prospect_pool = company.prospect_pools.create!(name: "Init PP")
    search = company.searches.create!(name: "Init Search", search_result_csv_url: "https://initurl.csv")

    sign_in create(:unlocked_admin)
    post :update, params: {
      format: "json",
      id: company.id,
      linked_in_accounts: [
        {
          name: "Foo Bar",
          email: "foo@bar.at",
          li_at: "foobar",
          frontend_id: "foobar",
        },
        {
          name: "Foo Bar 2",
          frontend_id: "foobar2",
        },
      ],
      company: {
        name: "New Name",
        prospect_pools: [
          {
            name: "Prospect Pool 1",
          },
          {
            name: "Prospect Pool 2",
          },
        ],
        campaigns: [
          {
            id: nil,
            name: "Campaign 1",
            linked_in_account_id: "foobar",
            prospect_pool_campaign_associations: [
              {
                prospect_pool_id: prospect_pool.id,
              },
              {
                prospect_pool_id: prospect_pool.id,
              },
            ],
            campaign_search_associations: [
              {
                search_id: search.id,
              },
              {
                search_id: search.id,
              },
            ],
            segments: [],
            linked_in_profile_scraper: {
              id: nil,
              daily_scraping_target: 35,
              active: true,
            },
          },
          {
            id: nil,
            name: "Campaign 2",
            linked_in_account_id: "foobar2",
          },
        ],
        searches: [
          name: "Search 1",
          search_result_csv_url: "http://someurl.csv",
        ],
        blacklist_imports: [
          csv_url: "http://someurl.csv",
        ],
      },
    }
    expect(response.status).to eq(200)
    expect(company.reload.name).to eq("New Name")
    expect(company.campaigns.size).to eq(2)
    expect(company.prospect_pools.size).to eq(3)
    expect(company.searches.size).to eq(2)
    expect(company.reload.campaigns.first.searches.first).to eq(search)
    expect(company.blacklist_imports.size).to eq(1)
    campaign1 = company.campaigns.where(name: "Campaign 1").first
    expect(campaign1.linked_in_profile_scraper.daily_scraping_target).to eq(35)
    expect(campaign1.linked_in_profile_scraper.active).to eq(true)
    linked_in_account = company.campaigns.where(name: "Campaign 1").first.linked_in_account
    expect(linked_in_account.li_at).to eq("foobar")

    post :update, params: {
      format: "json",
      id: company.id,
      linked_in_accounts: [
        {
          id: company.campaigns.where(name: "Campaign 1").first.linked_in_account.id,
          name: "Foo Bar",
          email: "foo@bar.at",
          li_at: "foobar2",
        },
      ],
      company: {
        name: "New Name",
        prospect_pools: [
          {
            name: "Prospect Pool 1",
          },
          {
            name: "Prospect Pool 2",
          },
        ],
        campaigns: [
          {
            id: nil,
            name: "Campaign 1",
            linked_in_account_id: company.campaigns.where(name: "Campaign 1").first.linked_in_account.id,
            prospect_pool_campaign_associations: [
              {
                prospect_pool_id: prospect_pool.id,
              },
              {
                prospect_pool_id: prospect_pool.id,
              },
            ],
            campaign_search_associations: [
              {
                search_id: search.id,
              },
              {
                search_id: search.id,
              },
            ],
            segments: [],
          },
        ],
      },
    }
    expect(company.campaigns.where(name: "Campaign 1").first.linked_in_account.li_at).to eq("foobar2")
    expect(company.campaigns.where(name: "Campaign 1").first.linked_in_account.id).to eq(linked_in_account.id)
  end

  it "can update linked in accounts" do
    # mock phantombuster api request
    stub_request(:post, "https://api.phantombuster.com/api/v2/agents/save").
      with(
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Content-Type' => 'application/json',
          'User-Agent' => 'Ruby',
          'X-Phantombuster-Key' => 'Y6VpQGeuDMf2AoPYSgURiUmuVeZd6aWL',
        }
      ).
      to_return(status: 200, body: '{"id": 8273271927}', headers: {})
    stub_request(:get, "https://phantombuster.com/api/v1/agent/130155/launch").
      with(
        query: hash_including({}),
        headers: {
          'Accept' => 'application/json',
          'X-Phantombuster-Key-1' => 'Y6VpQGeuDMf2AoPYSgURiUmuVeZd6aWL',
        }
      ).
      to_return(status: 200, body: '{"data": { "containerId": "barfoo" } }', headers: {})
    company = create(:company)
    # prospect_pool = company.prospect_pools.create!(name: "Init PP")
    # search = company.searches.create!(name: "Init Search", search_result_csv_url: "https://initurl.csv")
    sign_in create(:unlocked_admin)
    post :update, params: {
      format: "json",
      id: company.id,
      linked_in_accounts: [
        {
          frontend_id: "foobar",
          name: "Frederic Foobar",
          li_at: "session-cookie",
          email: "fred@foobar.com",
        },
      ],
      company: {
        name: "New Name",
        prospect_pools: [
          {
            name: "Prospect Pool 1",
          },
        ],
        campaigns: [],
        searches: [
          {
            uses_csv_import: false,
            name: "Some LI Search",
            linked_in_search_url: "blabla",
            linked_in_account_id: "foobar",
          },
        ],
        blacklist_imports: [],
      },
    }

    expect(LinkedInAccount.where(name: "Frederic Foobar").all.size).to eq(1)
    expect(company.searches.where(name: "Some LI Search").all.size).to eq(1)
    expect(company.searches.where(name: "Some LI Search").first.linked_in_account).to eq(LinkedInAccount.where(name: "Frederic Foobar").all.first)
  end

  it "correctly rolls back after a failed validation" do
    stub_request(:post, "https://api.phantombuster.com/api/v2/agents/save").
      with(
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Content-Type' => 'application/json',
          'User-Agent' => 'Ruby',
          'X-Phantombuster-Key' => 'Y6VpQGeuDMf2AoPYSgURiUmuVeZd6aWL',
        }
      ).
      to_return(status: 200, body: '{"id": 8273271927}', headers: {})
    company = create(:company)
    prospect_pool = company.prospect_pools.create!(name: "Init PP")
    search = company.searches.create!(name: "Init Search", search_result_csv_url: "https://initurl.csv")

    sign_in create(:unlocked_admin)
    post :update, params: {
      format: "json",
      id: company.id,
      linked_in_accounts: [
        {
          name: "Foo Bar",
          email: "foo@bar.at",
          li_at: "foobar",
          frontend_id: "foobar",
        },
      ],
      company: {
        name: "New Name",
        prospect_pools: [
          {
            name: "Prospect Pool 1",
          },
        ],
        campaigns: [
          {
            id: nil,
            name: "Campaign 1",
            linked_in_account_id: "foobar",
            prospect_pool_campaign_associations: [
              {
                prospect_pool_id: prospect_pool.id,
              },
            ],
            campaign_search_associations: [
              {
                search_id: search.id,
              },
            ],
            segments: [],
            linked_in_profile_scraper: {
              id: nil,
              daily_scraping_target: 35,
              active: true,
            },
          },
        ],
      },
    }
    expect(response.status).to eq(200)
    expect(company.reload.campaigns.first.searches.first).to eq(search)
    expect(company.reload.campaigns.first.prospect_pools.first.id).to eq(prospect_pool.id)

    post :update, params: {
      format: "json",
      id: company.id,
      company: {
        name: "New Name",
        prospect_pools: [],
        campaigns: [
          {
            id: company.reload.campaigns.first.id,
            name: "Campaign 1",
            linked_in_account_id: nil,
            prospect_pool_campaign_associations: [
              {
                prospect_pool_id: prospect_pool.id,
              },
            ],
            campaign_search_associations: [
              {
                search_id: search.id,
              },
            ],
            segments: [],
          },
        ],
      },
    }
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body).with_indifferent_access[:company][:campaigns].first[:errors].present?).to eq(true)
    expect(company.reload.campaigns.first.prospect_pools.first.id).to eq(prospect_pool.id)
    expect(company.reload.campaigns.first.searches.first).to eq(search)
  end

  it "can handle errors with linked in accounts" do
    # mock phantombuster api request
    stub_request(:post, "https://api.phantombuster.com/api/v2/agents/save").
      with(
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Content-Type' => 'application/json',
          'User-Agent' => 'Ruby',
          'X-Phantombuster-Key' => 'Y6VpQGeuDMf2AoPYSgURiUmuVeZd6aWL',
        }
      ).
      to_return(status: 200, body: '{"id": 8273271927}', headers: {})
    stub_request(:get, "https://phantombuster.com/api/v1/agent/130155/launch").
      with(
        query: hash_including({}),
        headers: {
          'Accept' => 'application/json',
          'X-Phantombuster-Key-1' => 'Y6VpQGeuDMf2AoPYSgURiUmuVeZd6aWL',
        }
      ).
      to_return(status: 200, body: '{"data": { "containerId": "barfoo" } }', headers: {})
    company = create(:company)
    # prospect_pool = company.prospect_pools.create!(name: "Init PP")
    # search = company.searches.create!(name: "Init Search", search_result_csv_url: "https://initurl.csv")
    sign_in create(:unlocked_admin)
    post :update, params: {
      format: "json",
      id: company.id,
      linked_in_accounts: [
        {
          frontend_id: "foobar",
          name: "",
          li_at: "",
          email: "",
        },
      ],
      company: {
        name: "New Name",
        prospect_pools: [
          {
            name: "Prospect Pool 1",
          },
        ],
        campaigns: [],
        searches: [
          {
            uses_csv_import: false,
            name: "Some LI Search",
            linked_in_search_url: "blabla",
            linked_in_account_id: "foobar",
          },
        ],
        blacklist_imports: [],
      },
    }

    expect(JSON.parse(response.body).with_indifferent_access[:linkedInAccounts].first[:errors].present?).to eq(true)
  end
end
