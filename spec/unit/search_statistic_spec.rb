require 'rails_helper'

RSpec.describe "Search Statistic" do
  it "can create a statistic for a search and understands that prospects can be contacted multiple times" do
    campaign = create(:campaign)
    search = campaign.company.searches.create!(name: "search name", search_result_csv_url: "foo.com/slash.csv")

    p1 = campaign.add_prospect!(linked_in_profile_url: "foo1")
    p1_assoc = p1.prospect_campaign_associations.first
    p1_assoc.linked_in_outreaches.create!(sent_connection_request_at: Time.at(0))
    p1.prospect_search_associations.create!(search: search, through_query: "query1")

    search.prepare_statistics

    expect(search.num_delivered).to eq(1)
    expect(search.num_accepted).to eq(0)
    expect(search.query_statistics.size).to eq(1)
    expect(search.query_statistics.first.filter_query).to eq("query1")
    expect(search.query_statistics.first.num_delivered).to eq(1)
    expect(search.query_statistics.first.num_accepted).to eq(0)

    campaign2 = create(:campaign)
    p1_assoc2 = campaign2.prospect_campaign_associations.create!(prospect: p1)
    outreach = p1_assoc2.linked_in_outreaches.create!(sent_connection_request_at: Time.at(1))
    outreach.update!(accepted_connection_request_at: Time.at(2))

    search = Search.find(search.id) # invalidates the cached first_outreach_date, last_outreach_date
    search.prepare_statistics

    expect(search.num_delivered).to eq(2)
    expect(search.num_accepted).to eq(1)
    expect(search.query_statistics.size).to eq(1)
    expect(search.query_statistics.first.filter_query).to eq("query1")
    expect(search.query_statistics.first.num_delivered).to eq(2)
    expect(search.query_statistics.first.num_accepted).to eq(1)
  end

  it "can create a statistic for a search and create campaign statistcs for the search" do
    campaign = create(:campaign, name: "Campaign 1")
    search = campaign.company.searches.create!(name: "search name", search_result_csv_url: "foo.com/slash.csv")

    p1 = campaign.add_prospect!(linked_in_profile_url: "foo1")
    p1_assoc = p1.prospect_campaign_associations.first
    p1_assoc.linked_in_outreaches.create!(sent_connection_request_at: Time.at(0))
    p1.prospect_search_associations.create!(search: search, through_query: "query1")

    # campaign1 has prospect that hasn't been contacted yet - should have no effect
    _p2 = campaign.add_prospect!(linked_in_profile_url: "foo3")

    campaign2 = create(:campaign, name: "Campaign 2")
    p1_assoc2 = campaign2.prospect_campaign_associations.create!(prospect: p1)
    outreach = p1_assoc2.linked_in_outreaches.create!(sent_connection_request_at: Time.at(24 * 60 * 60 + 1))
    outreach.update!(accepted_connection_request_at: Time.at(24 * 60 * 60 + 2))

    p2_2 = campaign.add_prospect!(linked_in_profile_url: "foo4")
    p2_2assoc = p2_2.prospect_campaign_associations.first
    p2_2assoc.linked_in_outreaches.create!(sent_connection_request_at: Time.at(24 * 60 * 60 + 5))
    p2_2.prospect_search_associations.create!(search: search, through_query: "query1")

    # campaign with prospect association but no outreaches will not show up in statistics
    campaign4 = create(:campaign, name: "Campaign 4")
    _p1_assoc4 = campaign4.prospect_campaign_associations.create!(prospect: p1)


    # to test campaign 3 doesnt show up anywhere -- it doesnt have any connection to this search
    campaign3 = create(:campaign, name: "Campaign 3")
    p2 = campaign3.add_prospect!(linked_in_profile_url: "foo2")
    p2_assoc = p2.prospect_campaign_associations.first
    p2_assoc.linked_in_outreaches.create!(sent_connection_request_at: Time.at(0))
    search_unrelated = campaign3.company.searches.create!(name: "search name", search_result_csv_url: "foo.com/slash.csv")
    p2.prospect_search_associations.create!(search: search_unrelated, through_query: "query_unrelated")

    expect(search.first_outreach_date).to eq(Time.at(0))
    expect(search.last_outreach_date).to eq(Time.at(24 * 60 * 60 + 5))

    search.statistics.delete_all
    search.prepare_daily_statistics

    daily_stats = search.daily_statistics
    expect(daily_stats.size).to eq(2)
    daily_stats = daily_stats.reverse
    expect(daily_stats.first.from).to eq(Time.at(0))
    expect(daily_stats.first.num_delivered).to eq(1)
    expect(daily_stats.first.num_accepted).to eq(0)

    expect(daily_stats.second.from).to eq(Time.at(24 * 60 * 60 + 1))
    expect(daily_stats.second.num_delivered).to eq(2)
    expect(daily_stats.second.num_accepted).to eq(1)

    full = search.full_statistic
    expect(full.num_delivered).to eq(3)
    expect(full.num_accepted).to eq(1)

    search.prepare_campaign_statistics

    campaign_stats = search.campaign_statistics
    expect(campaign_stats.size).to eq(2)
    campaign1_stats = campaign_stats.where(name: "Campaign 1").first
    expect(campaign1_stats.num_delivered).to eq(2)
    expect(campaign1_stats.num_accepted).to eq(0)

    campaign2_stats = campaign_stats.where(name: "Campaign 2").first
    expect(campaign2_stats.num_delivered).to eq(1)
    expect(campaign2_stats.num_accepted).to eq(1)
  end

  it "does not count errored outreaches" do
    campaign = create(:campaign, name: "Campaign 1")
    search = campaign.company.searches.create!(name: "search name", search_result_csv_url: "foo.com/slash.csv")

    p1 = campaign.add_prospect!(linked_in_profile_url: "foo1")
    p1_assoc = p1.prospect_campaign_associations.first
    p1_assoc.linked_in_outreaches.create!(sent_connection_request_at: Time.current, connection_request_error: "some error")
    p1.prospect_search_associations.create!(search: search, through_query: "query1")

    search.prepare_statistics
    expect(search.num_delivered).to eq(0)
    expect(search.daily_statistics.first.num_delivered).to eq(0)
    expect(search.campaign_statistics.size).to eq(0)

    p2 = campaign.add_prospect!(linked_in_profile_url: "foo2")
    p2_assoc = p2.prospect_campaign_associations.first
    p2_assoc.linked_in_outreaches.create!(sent_connection_request_at: Time.current)
    p2.prospect_search_associations.create!(search: search, through_query: "query1")

    search = Search.find(search.id) # invalidates the cached first_outreach_date, last_outreach_date
    search.prepare_statistics
    expect(search.num_delivered).to eq(1)
    expect(search.daily_statistics.first.num_delivered).to eq(1)
    expect(search.campaign_statistics.first.num_delivered).to eq(1)
  end
end
