require 'rails_helper'

RSpec.describe "LinkedInOutreach" do
  def create_outreach(sent_at, error, accepted_at)
    campaign = create(:campaign)
    p = campaign.add_prospect!(linked_in_profile_url: "foobar")
    LinkedInOutreach.create!(
      sent_connection_request_at: sent_at,
      connection_request_error: error,
      accepted_connection_request_at: accepted_at,
      prospect_campaign_association: p.prospect_campaign_associations.first
    )
  end

  it "knows which requests have a connection error" do
    travel_to Time.parse("2020-02-11") # time after error deadline
    create_outreach(Time.at(0), nil, nil)
    expect(LinkedInOutreach.with_connection_error.size).to eq(0)
    create_outreach(Time.at(10), "some error", nil)
    expect(LinkedInOutreach.with_connection_error.size).to eq(1)
    create_outreach(Time.at(10), "followup not sent", Time.at(100))
    expect(LinkedInOutreach.with_connection_error.size).to eq(1)
    create_outreach(Time.at(10), "some error", Time.at(100))
    expect(LinkedInOutreach.with_connection_error.size).to eq(1)
    create_outreach(Time.at(10), "shadow ban", nil)
    expect(LinkedInOutreach.with_connection_error.size).to eq(2)
  end

  it "knows which request do not have a connection error" do
    travel_to Time.parse("2020-02-11") # time after error deadline
    create_outreach(Time.at(0), nil, nil)
    expect(LinkedInOutreach.without_connection_error.size).to eq(1)
    create_outreach(Time.at(10), "some error", nil)
    expect(LinkedInOutreach.without_connection_error.size).to eq(1)
    create_outreach(Time.at(10), "followup not sent", Time.at(100))
    expect(LinkedInOutreach.without_connection_error.size).to eq(2)
    create_outreach(Time.at(10), "some error", Time.at(100))
    expect(LinkedInOutreach.without_connection_error.size).to eq(3)
    create_outreach(Time.at(10), "shadow ban", nil)
    expect(LinkedInOutreach.without_connection_error.size).to eq(3)
  end

  it "knows which requests do not have a connection error, or are before the error deadline" do
    travel_to Time.parse("2020-02-11") # time after error deadline
    create_outreach(Time.at(0), nil, nil)
    expect(LinkedInOutreach.without_connection_error_or_sent_before_deadline_where_errors_count.size).to eq(1)
    create_outreach(Time.at(0), "some error", nil)
    expect(LinkedInOutreach.without_connection_error_or_sent_before_deadline_where_errors_count.size).to eq(2)
    create_outreach(Time.current, "some error", nil)
    expect(LinkedInOutreach.without_connection_error_or_sent_before_deadline_where_errors_count.size).to eq(2)
  end
end
