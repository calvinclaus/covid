require 'rails_helper'

RSpec.describe Api::CampaignsController, type: :controller do
  it "triggers a sync when phantombuster agents ping the `executed` endpoint" do
    travel_to Time.at(1578480179)
    campaign = create(:campaign)
    Delayed::Job.all.delete_all
    expect(Delayed::Job.all.length).to eq(0)
    get :executed, params: {
      phantombuster_agent_id: campaign.phantombuster_agent_id,
      num_connections: 1500,
      account_type: "RECRUITER",
      key: ENV['OUR_API_KEY'],
    }
    expect(response.body).to eq("ok")
    expect(response.status).to eq(200)
    expect(Delayed::Job.all.length).to eq(1)
    campaign.reload
    expect(campaign.linked_in_account.num_connections).to eq(1500)
    expect(campaign.linked_in_account.account_type).to eq("RECRUITER")
    expect(campaign.invocations.size).to eq(1)
    expect(campaign.invocations.first.timestamp).to eq(Time.at(1578480179))
    travel_to Time.at(1578480179 + 60 * 60)
    # doesnt  schedule another one
    get :executed, params: {phantombuster_agent_id: campaign.phantombuster_agent_id, key: ENV['OUR_API_KEY']}
    expect(response.body).to eq("ok")
    expect(response.status).to eq(200)
    expect(campaign.invocations.size).to eq(2)
    expect(campaign.invocations.first.timestamp).to eq(Time.at(1578480179))
    expect(campaign.invocations.second.timestamp).to eq(Time.at(1578480179 + 60 * 60))
    expect(campaign.linked_in_account.num_connections).to eq(1500)
    expect(campaign.linked_in_account.account_type).to eq("RECRUITER")
    expect(Delayed::Job.all.length).to eq(1)
  end

  it "can handle logout" do
    campaign = create(:campaign)
    expect(campaign.linked_in_account.logged_in?).to eq(true)
    expect(campaign.linked_in_account.logouts.size).to eq(0)
    get :logged_out, params: {phantombuster_agent_id: campaign.phantombuster_agent_id, key: ENV['OUR_API_KEY']}
    expect(response.body).to eq("ok")
    expect(response.status).to eq(200)
    campaign.reload
    expect(campaign.linked_in_account.logged_in?).to eq(false)
    expect(campaign.linked_in_account.logouts.size).to eq(1)
    get :logged_out, params: {phantombuster_agent_id: campaign.phantombuster_agent_id, key: ENV['OUR_API_KEY']}
    expect(response.body).to eq("ok")
    expect(response.status).to eq(200)
    campaign.reload
    expect(campaign.linked_in_account.logged_in?).to eq(false)
    expect(campaign.linked_in_account.logouts.size).to eq(1)
    campaign.linked_in_account.update!(li_at: "logged-back-in")
    expect(campaign.linked_in_account.logged_in?).to eq(true)
    get :logged_out, params: {phantombuster_agent_id: campaign.phantombuster_agent_id, key: ENV['OUR_API_KEY']}
    expect(response.body).to eq("ok")
    expect(response.status).to eq(200)
    campaign.reload
    expect(campaign.linked_in_account.logged_in?).to eq(false)
    expect(campaign.linked_in_account.logouts.size).to eq(2)
  end

  it "deletes a logout if it detects that the logout wasn't actually a logout" do
    campaign = create(:campaign)
    expect(campaign.linked_in_account.logged_in?).to eq(true)
    expect(campaign.linked_in_account.logouts.size).to eq(0)
    get :logged_out, params: {phantombuster_agent_id: campaign.phantombuster_agent_id, key: ENV['OUR_API_KEY']}
    campaign.reload
    expect(campaign.linked_in_account.logged_in?).to eq(false)
    expect(campaign.linked_in_account.logouts.size).to eq(1)
    get :executed, params: {phantombuster_agent_id: campaign.phantombuster_agent_id, key: ENV['OUR_API_KEY']}
    campaign.reload
    expect(campaign.linked_in_account.logged_in?).to eq(true)
    expect(campaign.linked_in_account.logouts.size).to eq(0) # deleted logout
  end

  it "doesnt fail if there is no logout to delete if executed ping but account is set as logged out" do
    campaign = create(:campaign)
    campaign.linked_in_account.update!(logged_in: false)
    campaign.reload
    expect(campaign.linked_in_account.logged_in?).to eq(false)
    expect(campaign.linked_in_account.logouts.size).to eq(0)
    get :executed, params: {phantombuster_agent_id: campaign.phantombuster_agent_id, key: ENV['OUR_API_KEY']}
    campaign.reload
    expect(campaign.linked_in_account.logged_in?).to eq(true)
    expect(campaign.linked_in_account.logouts.size).to eq(0)
  end

  it "can handle unknown agent id" do
    create(:campaign)
    Delayed::Job.all.delete_all
    expect(Delayed::Job.all.length).to eq(0)
    get :executed, params: {phantombuster_agent_id: 11111, key: ENV['OUR_API_KEY']}
    expect(response.body).to eq("not found")
    expect(response.status).to eq(404)
    expect(Delayed::Job.all.length).to eq(0)
  end

  it "can handle unauthed user" do
    campaign = create(:campaign)
    Delayed::Job.all.delete_all
    expect(Delayed::Job.all.length).to eq(0)
    get :executed, params: {phantombuster_agent_id: campaign.phantombuster_agent_id, key: "wrongkey"}
    expect(response.body).to eq("not authenticated")
    expect(response.status).to eq(401)
    expect(Delayed::Job.all.length).to eq(0)
  end

  it "knows if one of the sent companies is on the campaign's company's blacklist" do
    FactoryBot.rewind_sequences
    campaign = create(:campaign, company: create(:company_with_blacklist))
    get :blacklist_has_one_of, params: {
      phantombuster_agent_id: campaign.phantombuster_agent_id,
      companies: ["Media Shop", "Another On Blacklist", "Non Existent"],
      key: ENV['OUR_API_KEY'],
    }
    expect(JSON.parse(response.body)).to eq({
      response: true,
      companies_on_blacklist: ["Media Shop", "Another On Blacklist"],
    }.stringify_keys)
  end

  it "knows if none of the sent companies is on the campaign's company's blacklist" do
    FactoryBot.rewind_sequences
    campaign = create(:campaign, company: create(:company_with_blacklist))
    get :blacklist_has_one_of, params: {
      phantombuster_agent_id: campaign.phantombuster_agent_id,
      companies: ["Non Existent"],
      key: ENV['OUR_API_KEY'],
    }
    expect(JSON.parse(response.body)).to eq({
      response: false,
      companies_on_blacklist: [],
    }.stringify_keys)
  end

  it "can handle an empty blacklist" do
    FactoryBot.rewind_sequences
    campaign = create(:campaign, company: create(:company))
    get :blacklist_has_one_of, params: {
      phantombuster_agent_id: campaign.phantombuster_agent_id,
      companies: ["Media Shop", "Another On Blacklist", "Non Existent"],
      key: ENV['OUR_API_KEY'],
    }
    expect(JSON.parse(response.body)).to eq({
      response: false,
      companies_on_blacklist: [],
    }.stringify_keys)
  end

  it "can handle an empty company array in request" do
    FactoryBot.rewind_sequences
    campaign = create(:campaign, company: create(:company_with_blacklist))
    get :blacklist_has_one_of, params: {
      phantombuster_agent_id: campaign.phantombuster_agent_id,
      companies: [],
      key: ENV['OUR_API_KEY'],
    }
    expect(JSON.parse(response.body)).to eq({
      response: false,
      companies_on_blacklist: [],
    }.stringify_keys)
  end

  it "knows if campaign has a blacklist" do
    campaign = create(:campaign, company: create(:company_with_blacklist))
    get :has_blacklist, params: {
      phantombuster_agent_id: campaign.phantombuster_agent_id,
      key: ENV['OUR_API_KEY'],
    }
    expect(JSON.parse(response.body)).to eq({
      response: true,
      size: 3,
    }.stringify_keys)
  end

  it "knows if campaign doesn't have a blacklist" do
    campaign = create(:campaign, company: create(:company))
    get :has_blacklist, params: {
      phantombuster_agent_id: campaign.phantombuster_agent_id,
      key: ENV['OUR_API_KEY'],
    }
    expect(JSON.parse(response.body)).to eq({
      response: false,
      size: 0,
    }.stringify_keys)
  end

  it "can next_prospects for a campaign in order of searches" do
    header = "profileUrl", "name", "cleanName", "title", "companyName", "companyLinkedInUrl", "id", "query"
    campaign = create(:campaign, company: create(:company))
    search1 = create(:search, company: campaign.company)
    search2 = create(:search, company: campaign.company)
    campaign.campaign_search_associations.create!(search: search2)
    campaign.campaign_search_associations.create!(search: search1)

    expect(next_prospects(campaign)).to eq([header])

    p1 = campaign.add_prospect!(linked_in_profile_url: "url_1/", name: "Lukas Bauer", title: "Title 1", primary_company_name: "Company Name", primary_company_linkedin_url: "foobar.com")
    p1.prospect_search_associations.create!(search: search1)

    expect(next_prospects(campaign)).to eq([
      header,
      ["url_1/", "Lukas Bauer", "Lukas Bauer", "Title 1", "Company Name", "foobar.com", p1.id.to_s, nil],
    ])

    p2 = campaign.add_prospect!(linked_in_profile_url: "url_2/", name: "Anita Frederik", title: "Title 2")
    p2.prospect_search_associations.create!(search: search2)


    p3 = campaign.add_prospect!(linked_in_profile_url: "url_3/", name: "Felix Bernold", title: "Title 3")
    p3.prospect_search_associations.create!(search: search1)
    p3.prospect_search_associations.create!(search: search2)

    unrelated_campaign = create(:campaign, company: campaign.company)
    unrelated_prospect = unrelated_campaign.add_prospect!(linked_in_profile_url: "unrelated/", name: "Unrelated")
    unrelated_prospect.prospect_search_associations.create!(search: search1)
    unrelated_prospect.prospect_search_associations.create!(search: search2)

    expect(next_prospects(campaign)).to eq([
      header,
      ["url_2/", "Anita Frederik", "Anita Frederik", "Title 2", nil, nil, p2.id.to_s, nil],
      ["url_3/", "Felix Bernold", "Felix Bernold", "Title 3", nil, nil, p3.id.to_s, nil],
      ["url_1/", "Lukas Bauer", "Lukas Bauer", "Title 1", "Company Name", "foobar.com", p1.id.to_s, nil],
    ])
    assoc = p1.prospect_campaign_associations.where(campaign: campaign).first
    assoc.linked_in_outreaches.create!(sent_connection_request_at: DateTime.new)

    expect(next_prospects(campaign)).to eq([
      header,
      ["url_2/", "Anita Frederik", "Anita Frederik", "Title 2", nil, nil, p2.id.to_s, nil],
      ["url_3/", "Felix Bernold", "Felix Bernold", "Title 3", nil, nil, p3.id.to_s, nil],
    ])

    p2.blacklisted = true
    p2.save!

    expect(next_prospects(campaign)).to eq([
      header,
      ["url_3/", "Felix Bernold", "Felix Bernold", "Title 3", nil, nil, p3.id.to_s, nil],
    ])
  end

  it "can next_prospects for a campaign" do
    header = "profileUrl", "name", "cleanName", "title", "companyName", "companyLinkedInUrl", "id", "query"
    campaign = create(:campaign, company: create(:company))
    expect(next_prospects(campaign)).to eq([header])

    p1 = campaign.add_prospect!(linked_in_profile_url: "url_1/", name: "Lukas Bauer", title: "Title 1")
    expect(next_prospects(campaign)).to eq([
      header,
      ["url_1/", "Lukas Bauer", "Lukas Bauer", "Title 1", nil, nil, p1.id.to_s, nil],
    ])

    p2 = campaign.add_prospect!(linked_in_profile_url: "url_2/", name: "Anita Frederik", title: "Title 2")
    expect(next_prospects(campaign)).to eq([
      header,
      ["url_1/", "Lukas Bauer", "Lukas Bauer", "Title 1", nil, nil, p1.id.to_s, nil],
      ["url_2/", "Anita Frederik", "Anita Frederik", "Title 2", nil, nil, p2.id.to_s, nil],
    ])
    assoc = p1.prospect_campaign_associations.where(campaign: campaign).first
    assoc.linked_in_outreaches.create!(sent_connection_request_at: DateTime.new)

    expect(next_prospects(campaign)).to eq([
      header,
      ["url_2/", "Anita Frederik", "Anita Frederik", "Title 2", nil, nil, p2.id.to_s, nil],
    ])

    p2.blacklisted = true
    p2.save!

    expect(next_prospects(campaign)).to eq([
      header,
    ])
  end

  def next_prospects(campaign)
    get :next_prospects_with_id, params: {
      id: campaign.id,
      key: ENV['OUR_API_KEY'],
    }
    CSV.parse(response.body.force_encoding("UTF-8").encode("UTF-8"), encoding: "UTF-8")
  end
end
