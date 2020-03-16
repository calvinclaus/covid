require 'rails_helper'
RSpec.describe "Statistic Spec" do
  it "can calculate query statistics" do
    campaign = create(:campaign)
    search = campaign.company.searches.create!(name: "search name", search_result_csv_url: "foo.com/slash.csv")
    search2 = campaign.company.searches.create!(name: "search name2", search_result_csv_url: "foo.com/slash2.csv")

    p1 = campaign.add_prospect!(linked_in_profile_url: "foo1")
    p1_assoc = p1.prospect_campaign_associations.first
    p1_assoc.linked_in_outreaches.create!(sent_connection_request_at: Time.at(0))
    p1.prospect_search_associations.create!(search: search, through_query: "query1")

    p2 = campaign.add_prospect!(linked_in_profile_url: "foo2")
    p2_assoc = p2.prospect_campaign_associations.first
    p2_outreach = p2_assoc.linked_in_outreaches.create!(sent_connection_request_at: Time.at(60 * 60))
    p2.prospect_search_associations.create!(search: search, through_query: "query2")
    p2_outreach.update!(follow_up_stage_at_time_of_reply: 1)

    p3 = campaign.add_prospect!(linked_in_profile_url: "foo3")
    p3_assoc = p3.prospect_campaign_associations.first
    p3_outreach = p3_assoc.linked_in_outreaches.create!(sent_connection_request_at: Time.at(60 * 60 * 2))
    p3.prospect_search_associations.create!(search: search, through_query: "query2")
    p3_outreach.update!(follow_up_stage_at_time_of_reply: 1)

    p4 = campaign.add_prospect!(linked_in_profile_url: "foo4")
    p4_assoc = p4.prospect_campaign_associations.first
    p4_outreach = p4_assoc.linked_in_outreaches.create!(sent_connection_request_at: Time.at(60 * 60 * 3))
    p4.prospect_search_associations.create!(search: search, through_query: "query2")
    p4.prospect_search_associations.create!(search: search2, through_query: "query3")
    p4_outreach.update!(follow_up_stage_at_time_of_reply: 0)

    campaign.prepare_statistics

    # query3 is first, as it was the last to have its first prospect contacted
    stat1 = campaign.query_statistics.third
    stat2 = campaign.query_statistics.second
    stat3 = campaign.full_statistic
    stat4 = campaign.query_statistics.first

    expect(stat1.num_delivered).to eq(1)
    expect(stat2.num_delivered).to eq(3)
    expect(stat4.num_delivered).to eq(1)
    expect(stat3.num_delivered).to eq(4)

    expect(stat1.num_replied_after_stage).to eq([])
    expect(stat2.num_replied_after_stage).to match_array([{follow_up_stage_at_time_of_reply: 0, count: 1}.stringify_keys, {follow_up_stage_at_time_of_reply: 1, count: 2}.stringify_keys])
    expect(stat4.num_replied_after_stage).to match_array([{follow_up_stage_at_time_of_reply: 0, count: 1}.stringify_keys])
    expect(stat3.num_replied_after_stage).to match_array([{follow_up_stage_at_time_of_reply: 0, count: 1}.stringify_keys, {follow_up_stage_at_time_of_reply: 1, count: 2}.stringify_keys])
  end

  it "does not count errored outreaches" do
    travel_to Time.parse("2020-02-12")
    campaign = create(:campaign, name: "Campaign 1")
    search = campaign.company.searches.create!(name: "search name", search_result_csv_url: "foo.com/slash.csv")

    p1 = campaign.add_prospect!(linked_in_profile_url: "foo1")
    p1_assoc = p1.prospect_campaign_associations.first
    p1_assoc.linked_in_outreaches.create!(sent_connection_request_at: Time.current, connection_request_error: "some error")
    p1.prospect_search_associations.create!(search: search, through_query: "query1")

    campaign.prepare_statistics

    expect(campaign.num_delivered).to eq(0)
    expect(campaign.daily_statistics.first.num_delivered).to eq(0)
    expect(campaign.search_statistics.size).to eq(0)

    p2 = campaign.add_prospect!(linked_in_profile_url: "foo2")
    p2_assoc = p2.prospect_campaign_associations.first
    p2_assoc.linked_in_outreaches.create!(sent_connection_request_at: Time.current)
    p2.prospect_search_associations.create!(search: search, through_query: "query1")

    campaign = Campaign.find(campaign.id) # invalidates the cached first_outreach_date, last_outreach_date
    campaign.prepare_statistics
    expect(campaign.num_delivered).to eq(1)
    expect(campaign.daily_statistics.first.num_delivered).to eq(1)
    expect(campaign.search_statistics.first.num_delivered).to eq(1)
  end
end
