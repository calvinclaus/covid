require 'rails_helper'

RSpec.describe "LinkedInProfileScraper" do
  it "sets launch_times correctly" do
    scraper = create(:linked_in_profile_scraper)
    expect(scraper.daily_scraping_target).to eq(40)

    launch_times_saved = scraper.launch_times

    expect(scraper.launch_times[:hour].size).to eq(4)
    expect(scraper.launch_times[:minute].size).to eq(1)
    expect(scraper.launch_times[:day].size).to eq(31)
    expect(scraper.launch_times[:month].size).to eq(12)

    expect(scraper.launch_times).to eq(launch_times_saved)
    expect(scraper.launch_times).to eq(launch_times_saved)
    scraper.touch
    expect(scraper.launch_times).to eq(launch_times_saved)
    scraper.update!(daily_scraping_target: 45)
    expect(scraper.launch_times[:hour].size).to eq(5)
  end

  it "executes the scraper when its time" do
    offset = 1577836800
    travel_to Time.at(0 + offset)

    scraper = create(:linked_in_profile_scraper, active: true)
    lts = scraper.launch_times
    lts[:timezone] = "UTC"
    scraper.update!(cached_launch_times: lts)
    expect(scraper.launch_times[:minute].first).to eq(55)

    first_hour = scraper.launch_times[:hour].first

    travel_to Time.at(first_hour * 60 * 60 + 54 * 60 + offset)
    LinkedInProfileScraper.tick
    expect(Delayed::Job.all.size).to eq(0)

    travel_to Time.at(first_hour * 60 * 60 + 55 * 60 + offset)
    LinkedInProfileScraper.tick
    expect(Delayed::Job.all.size).to eq(1)
    # does not run again
    LinkedInProfileScraper.tick
    expect(Delayed::Job.all.size).to eq(1)

    travel_to Time.at(first_hour * 60 * 60 + 56 * 60 + offset)
    LinkedInProfileScraper.tick
    expect(Delayed::Job.all.size).to eq(1)

    second_hour = scraper.launch_times[:hour].second
    travel_to Time.at(second_hour * 60 * 60 + 54 * 60 + offset)
    LinkedInProfileScraper.tick
    expect(Delayed::Job.all.size).to eq(1)

    travel_to Time.at(second_hour * 60 * 60 + 55 * 60 + offset)
    LinkedInProfileScraper.tick
    expect(Delayed::Job.all.size).to eq(2)
    travel_to Time.at(second_hour * 60 * 60 + 55 * 60 + 5 + offset)
    # does not run again
    LinkedInProfileScraper.tick
    expect(Delayed::Job.all.size).to eq(2)

    travel_to Time.at(second_hour * 60 * 60 + 56 * 60 + offset)
    LinkedInProfileScraper.tick
    expect(Delayed::Job.all.size).to eq(2)
  end

  it "takes into account timezone offset" do
    offset = 1577836800
    travel_to Time.at(0 + offset)

    scraper = create(:linked_in_profile_scraper, active: true)
    lts = scraper.launch_times
    lts[:timezone] = "Sydney"
    scraper.update!(cached_launch_times: lts)
    expect(scraper.launch_times[:minute].first).to eq(55)

    first_hour = scraper.launch_times[:hour].first

    timezone_offset = -60 * 60 * 11
    expect(Time.now.in_time_zone("Sydney").utc_offset).to eq(-timezone_offset)

    travel_to Time.at(first_hour * 60 * 60 + 54 * 60 + timezone_offset + offset)
    LinkedInProfileScraper.tick
    expect(Delayed::Job.all.size).to eq(0)

    travel_to Time.at(first_hour * 60 * 60 + 55 * 60 + timezone_offset + offset)
    LinkedInProfileScraper.tick
    expect(Delayed::Job.all.size).to eq(1)
    # does not run again
    LinkedInProfileScraper.tick
    expect(Delayed::Job.all.size).to eq(1)

    travel_to Time.at(first_hour * 60 * 60 + 56 * 60 + timezone_offset + offset)
    LinkedInProfileScraper.tick
    expect(Delayed::Job.all.size).to eq(1)

    second_hour = scraper.launch_times[:hour].second
    travel_to Time.at(second_hour * 60 * 60 + 54 * 60 + timezone_offset + offset)
    LinkedInProfileScraper.tick
    expect(Delayed::Job.all.size).to eq(1)

    travel_to Time.at(second_hour * 60 * 60 + 55 * 60 + timezone_offset + offset)
    LinkedInProfileScraper.tick
    expect(Delayed::Job.all.size).to eq(2)
    travel_to Time.at(second_hour * 60 * 60 + 55 * 60 + 5 + timezone_offset + offset)
    # does not run again
    LinkedInProfileScraper.tick
    expect(Delayed::Job.all.size).to eq(2)

    travel_to Time.at(second_hour * 60 * 60 + 56 * 60 + timezone_offset + offset)
    LinkedInProfileScraper.tick
    expect(Delayed::Job.all.size).to eq(2)
  end

  it "can scrape" do
    scraper = create(:linked_in_profile_scraper, active: true)
    campaign = scraper.campaign

    stub_request(:any, %r{7091889138671643/launch}).
      with(body: hash_including({})).
      to_return(
        status: 200, body: {data: {containerId: "container-1"}}.to_json, headers: {'Content-Type': 'application/json'},
      )

    stub_request(:get, "https://phantombuster.com/api/v1/agent/7091889138671643/output?containerId=container-1&mode=track&withoutResultObject=true").
      to_return(
        status: 200, body: {data: {progress: nil, containerStatus: "not running", output: "fooabr\n(exit code: 0)"}}.to_json, headers: {'Content-Type': 'application/json'},
      )

    stub_request(:get, "https://phantombuster.com/api/v1/agent/7091889138671643").
      with(
        headers: {
          'Accept' => 'application/json',
          'X-Phantombuster-Key-1' => 'Y6VpQGeuDMf2AoPYSgURiUmuVeZd6aWL',
        }
      ).
      to_return(
        status: 200,
        body: {status: "success", data: {userAwsFolder: "foo", awsFolder: "bar"}}.to_json,
        headers: {'Content-Type': 'application/json'}
      )

    stub_request(:get, %r{/foo/bar/dev-dashboard-pb-execution-.*\.csv}).
      to_return(
        status: 200, body: File.read('fixtures/csvs/profile-scraper-1.csv'),
      )


    p1 = campaign.add_prospect!(linked_in_profile_url: "https://www.linkedin.com/in/manuel-zant-28612813b")
    p1.prospect_campaign_associations.first.linked_in_outreaches.create!(
      sent_connection_request_at: DateTime.now - 1.days,
      accepted_connection_request_at: DateTime.now - 60.minutes,
    )

    p_scraping_error = campaign.add_prospect!(linked_in_profile_url: "https://www.linkedin.com/in/giovanna-angerame-zmugg-731ab241")
    p_scraping_error.prospect_campaign_associations.first.linked_in_outreaches.create!(
      sent_connection_request_at: DateTime.now - 2.days,
      accepted_connection_request_at: DateTime.now - 60.minutes,
    )

    p_first = campaign.add_prospect!(linked_in_profile_url: "https://www.linkedin.com/in/karl-barbach-58450a13a")
    p_first.prospect_campaign_associations.first.linked_in_outreaches.create!(
      sent_connection_request_at: DateTime.now - 5.days,
      accepted_connection_request_at: DateTime.now - 60.minutes,
    )

    p_not_connected = campaign.add_prospect!(linked_in_profile_url: "https://www.linkedin.com/in/not-connected")
    p_not_connected.prospect_campaign_associations.first.linked_in_outreaches.create!(
      sent_connection_request_at: DateTime.now - 1.days,
      accepted_connection_request_at: nil,
    )

    urls = scraper.next_profiles_to_scrape.map(&:linked_in_profile_url)
    expect(urls).to eq([
      "https://www.linkedin.com/in/karl-barbach-58450a13a/", # is first in line as first request sent
      "https://www.linkedin.com/in/giovanna-angerame-zmugg-731ab241/",
      "https://www.linkedin.com/in/manuel-zant-28612813b/",
    ])


    scraper.scrape

    execute_all_jobs

    expect(p1.linked_in_profile_scraper_results.first.email).to eq("manuel.zant@aon.at")
    expect(p1.linked_in_profile_scraper_results.first.phone).to eq("+436645307097")
    expect(p1.linked_in_profile_scraper_results.first.error).to eq(nil)
    expect(p_first.linked_in_profile_scraper_results.first.email).to eq("k.barbach@kabsi.at")
    expect(p_scraping_error.linked_in_profile_scraper_results.first.email).to eq(nil)
    expect(p_scraping_error.linked_in_profile_scraper_results.first.error).to eq("unavailable")

    urls = scraper.next_profiles_to_scrape.map(&:linked_in_profile_url)

    expect(urls).to eq([])
    # checking doesn't explode on empty input
    scraper.scrape
    execute_all_jobs
  end


  def execute_all_jobs
    jobs = Delayed::Job.all.size
    (0...jobs).each do |_i|
      execute_next_job
    end
    Delayed::Job.all.size
  end

  def execute_next_job
    job = Delayed::Job.all.first
    job.invoke_job
    job.delete
    Delayed::Job.all.size
  end
end
