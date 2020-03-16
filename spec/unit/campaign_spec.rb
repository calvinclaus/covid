require 'rails_helper'

VCR.configure do |config|
  config.cassette_library_dir = "fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.ignore_localhost = true
end

RSpec.describe "Campaign" do
  it "can represent linkedin sales navigator search urls as summarized text" do
    # puts Campaign.sales_nav_search_query_description("https://www.linkedin.com/sales/search/people?companySize=I&doFetchHeroCard=false&geoIncluded=103883259&industryExcluded=133%2C141%2C27%2C30%2C31&logHistory=true&logId=3571495356&rsLogId=103722084&searchSessionId=8AQHZ27xQZeaLQcKycnxsA%3D%3D&seniorityIncluded=5&yearsOfExperience=5")
    # puts Campaign.sales_nav_search_query_description("https://www.linkedin.com/sales/search/people?companySize=E%2CF%2CG%2CH%2CI&doFetchHeroCard=false&geoIncluded=103883259&industryExcluded=133%2C141%2C27%2C30%2C31&logHistory=true&logId=3571495356&rsLogId=103722084&searchSessionId=8AQHZ27xQZeaLQcKycnxsA%3D%3D&seniorityIncluded=5&tenureAtCurrentCompany=1&yearsOfExperience=5")
    # puts Campaign.sales_nav_search_query_description("https://www.linkedin.com/sales/search/people?companySize=E%2CF%2CG%2CH%2CI&doFetchHeroCard=false&geoIncluded=104669944%2C107144641&industryExcluded=133%2C141%2C27%2C30%2C31&logHistory=true&logId=8512431073&page=1&rsLogId=128693609&searchSessionId=8AQHZ27xQZeaLQcKycnxsA%3D%3D&spotlight=RECENTLY_POSTED_ON_LINKEDIN&tenureAtCurrentCompany=1%2C2%2C3%2C4%2C5")
    # puts Campaign.sales_nav_search_query_description("https://www.linkedin.com/sales/search/people?companySize=E%2CF%2CG%2CH%2CI&doFetchHeroCard=false&geoIncluded=103883259&industryExcluded=133%2C141%2C27%2C30%2C31&logHistory=true&logId=3571495356&rsLogId=103722084&searchSessionId=8AQHZ27xQZeaLQcKycnxsA%3D%3D&seniorityIncluded=5&spotlight=RECENTLY_POSTED_ON_LINKEDIN&yearsOfExperience=5")
    # puts Campaign.sales_nav_search_query_description("https://www.linkedin.com/sales/search/people?doFetchHeroCard=false&functionIncluded=12&geoIncluded=103883259&logHistory=true&logId=8522609323&page=1&relationship=S%2CO&rsLogId=131089313&searchSessionId=gczzZWIvRdOOdKfIHYQhnA%3D%3D&seniorityExcluded=1%2C2&seniorityIncluded=5%2C6")
    expect(Campaign.sales_nav_search_query_description("https://www.linkedin.com/sales/search/people?doFetchHeroCard=true&keywords=%22Marketing%20Automation%22&logHistory=true&logId=3959843524&rsLogId=148151434&schoolIncluded=154070%2C11723%2C11782%2C11811&searchSessionId=a0UCJK6lT3q%2BLuKIfElDuQ%3D%3D")).to eq("Keywords: \"Marketing Automation\"")
  end

  it "can sync a search even if its prospects have partially already been contacted" do
    campaign = create(:campaign_belonging_to_prospect_pool, company: create(:company_with_prospect_pool))
    company = campaign.company

    verify_sync(campaign: campaign, prospect_size: 8)

    search = create(:search, company: company)
    campaign.campaign_search_associations.create!(search: search)
    stub_request(:get, "https://phantombuster.s3.amazonaws.com/userAws/awsfoldertest/some-search.csv").to_return(
      status: 200, body: File.read('fixtures/csvs/search-to-calvin-llg-results-1.csv')
    )
    expect(company.prospects.all.first.primary_company_name).to eq(nil)
    Search::SearchResultSync.perform_now(search)
    expect(company.prospects.all.first.primary_company_name).to eq("Trodat GmbH")

    company.distribute_prospects_to_campaigns_idempotently
    expect(company.prospects.all.size).to eq(9)
    expect(campaign.reload.prospects.all.size).to eq(9)
    expect(company.prospects.all.first.linked_in_outreach(campaign)).to_not eq(nil)
    expect(company.prospects.all.last.linked_in_outreach(campaign)).to eq(nil)

    verify_sync(campaign: campaign, prospect_size: 9)
  end

  it "can deal with the same prospect being found by two searches" do
    # the dicciculty is that the phantombuster result file might have a different base_url than is currenlty
    # saved with the prospect.linked_in_profile_url, as different searches yield different profile_urls
    campaign = create(:campaign_belonging_to_prospect_pool, company: create(:company_with_prospect_pool))
    company = campaign.company
    search1 = create(:search, company: company)
    search2 = create(:search, company: company, search_result_csv_url: "https://phantombuster.s3.amazonaws.com/userAws/awsfoldertest/some-search-2.csv")

    stub_request(:get, "https://phantombuster.s3.amazonaws.com/userAws/awsfoldertest/some-search.csv").to_return(
      status: 200, body: File.read('fixtures/csvs/search-3.csv'),
    )
    stub_request(:get, "https://phantombuster.s3.amazonaws.com/userAws/awsfoldertest/some-search-2.csv").to_return(
      status: 200, body: File.read('fixtures/csvs/search-3-same-result-different-sales-nav-url.csv'),
    )
    Search::SearchResultSync.perform_now(search1)
    Search::SearchResultSync.perform_now(search2)

    campaign.campaign_search_associations.create!(search: search1)
    campaign.campaign_search_associations.create!(search: search2)
    expect(company.reload.prospects.size).to eq(1)
    expect(campaign.reload.prospects.size).to eq(0)
    company.distribute_prospects_to_campaigns_idempotently
    expect(campaign.reload.prospects.size).to eq(1)

    # now the prospect is identified with this sales-nav-url
    expect(campaign.prospects.size).to eq(1)
    expect(campaign.prospects.first.linked_in_profile_url).to eq("https://www.linkedin.com/sales/people/ACwAAAXycB8B5wfHohYI20i81vwgFuRBa3qdlHk,NAME_SEARCH,sTOm?_ntb=from-first-search/") # original url not overwritten
    expect(campaign.prospects.first.linked_in_profile_url_from_search).to eq("https://www.linkedin.com/sales/people/ACwAAAXycB8B5wfHohYI20i81vwgFuRBa3qdlHk,NAME_SEARCH,sTOm?_ntb=from-second-search/") # from search url overwritten by second search


    stub_request(:get, "https://phantombuster.com/api/v1/agent/144053").
      with(headers: {'X-Phantombuster-Key-1' => 'Y6VpQGeuDMf2AoPYSgURiUmuVeZd6aWL'}).
      to_return(status: 200, body: '{"status":"success","data":{"id":144053,"name":"LLG_DEV / Patrick Wind LLG","scriptId":20699,"proxy":"none","proxyAddress":null,"proxyUsername":null,"proxyPassword":null,"disableWebSecurity":true,"ignoreSslErrors":true,"loadImages":true,"launch":"manually","nbLaunches":77,"showDebug":true,"awsFolder":"awsfoldertest","executionTimeLimit":10,"fileMgmt":"mix","fileMgmtMaxFolders":5,"lastEndMessage":"Agent finished (success)","lastEndStatus":"success","maxParallelExecs":0,"nbRetries":0,"nonce":167,"slackHook":null,"userAwsFolder":"userAws"}}', headers: {})

    stub_request(:get, "https://phantombuster.s3.amazonaws.com/userAws/awsfoldertest/database-linkedin-network-booster.csv").to_return(
      status: 200, body: File.read('fixtures/csvs/search-3-results.csv'),
    )

    (1..3).each do |i|
      # to test if reimporting searches breaks stuff
      if i == 2
        Search::SearchResultSync.perform_now(search1)
        Search::SearchResultSync.perform_now(search2)
      else
        Campaign::PhantombusterSync.perform_now(campaign)
      end

      expect(company.prospects.all.size).to eq(1)
      expect(campaign.prospects.all.size).to eq(1)

      prospect = company.prospects.first
      expect(prospect.name).to eq("Niko Rustemeyer")
      expect(prospect.linked_in_profile_url).to eq("https://www.linkedin.com/in/niko-rustemeyer-a534b729/") # trailing slash added even though csv doesnt have
      expect(prospect.linked_in_profile_url_from_search).to include("https://www.linkedin.com/sales/people/ACwAAAXycB8B5wfHohYI20i81vwgFuRBa3qdlHk,NAME_SEARCH,sTOm?_ntb") # we dont care which of the two urls it is now

      expect(prospect.vmid).to eq("ACwAAAXycB8B5wfHohYI20i81vwgFuRBa3qdlHk")
      outreach = prospect.linked_in_outreach(campaign)
      expect(outreach.connection_message).to include("Hey Niko,\n")
      expect(outreach.sent_connection_request_at).to eq(DateTime.parse('2019-07-08T17:25:33.223Z'))
      expect(outreach.follow_up_messages).to eq([])
      expect(outreach.follow_up_stage_at_time_of_reply).to eq(nil)
    end
  end

  it "can sync a non sales navigator search" do
    campaign = create(:campaign_belonging_to_prospect_pool, company: create(:company_with_prospect_pool))
    company = campaign.company

    search = create(:search, company: company)
    campaign.campaign_search_associations.create!(search: search)
    stub_request(:get, "https://phantombuster.s3.amazonaws.com/userAws/awsfoldertest/some-search.csv").to_return(
      status: 200, body: File.read('fixtures/csvs/non-sales-nav-search.csv')
    )

    Search::SearchResultSync.perform_now(search)


    stub_request(:get, "https://phantombuster.com/api/v1/agent/144053").
      with(headers: {'X-Phantombuster-Key-1' => 'Y6VpQGeuDMf2AoPYSgURiUmuVeZd6aWL'}).
      to_return(status: 200, body: '{"status":"success","data":{"id":144053,"name":"LLG_DEV / Patrick Wind LLG","scriptId":20699,"proxy":"none","proxyAddress":null,"proxyUsername":null,"proxyPassword":null,"disableWebSecurity":true,"ignoreSslErrors":true,"loadImages":true,"launch":"manually","nbLaunches":77,"showDebug":true,"awsFolder":"awsfoldertest","executionTimeLimit":10,"fileMgmt":"mix","fileMgmtMaxFolders":5,"lastEndMessage":"Agent finished (success)","lastEndStatus":"success","maxParallelExecs":0,"nbRetries":0,"nonce":167,"slackHook":null,"userAwsFolder":"userAws"}}', headers: {})

    stub_request(:get, "https://phantombuster.s3.amazonaws.com/userAws/awsfoldertest/database-linkedin-network-booster.csv").to_return(
      status: 200, body: File.read('fixtures/csvs/non-sales-nav-search-results.csv'),
    )

    # no matter how often we call, the result remains the same with unchanged csv data
    (1..3).each do |_i|
      Campaign::PhantombusterSync.perform_now(campaign)

      expect(company.prospects.all.size).to eq(1)
      expect(campaign.prospects.all.size).to eq(1)

      prospect = campaign.prospects.first
      outreach = prospect.linked_in_outreach(campaign)
      expect(prospect.linked_in_profile_url).to eq("https://www.linkedin.com/in/mary-funkhouser-9b185a6/")
      expect(prospect.title).to eq("Summary: ...Indep. Affiliate of Gifted Travel Network—a Virtuoso® Member")
      expect(prospect.primary_company_name).to eq(nil)
      expect(prospect.vmid).to eq(nil)

      expect(outreach.connection_message).to eq("Message!")

      Search::SearchResultSync.perform_now(search)
    end
  end

  it "will update daily request target and people count to keep after syncing" do
    campaign = create(:campaign)

    stub_request(:get, "https://phantombuster.com/api/v1/agent/144053").
      with(headers: {'X-Phantombuster-Key-1' => 'Y6VpQGeuDMf2AoPYSgURiUmuVeZd6aWL'}).
      to_return(status: 200, body: '{"status":"success","data":{"id":144053,"name":"LLG_DEV / Patrick Wind LLG","scriptId":20699,"proxy":"none","proxyAddress":null,"proxyUsername":null,"proxyPassword":null,"disableWebSecurity":true,"ignoreSslErrors":true,"loadImages":true,"launch":"manually","nbLaunches":77,"showDebug":true,"awsFolder":"awsfoldertest","executionTimeLimit":10,"fileMgmt":"mix","fileMgmtMaxFolders":5,"lastEndMessage":"Agent finished (success)","lastEndStatus":"success","maxParallelExecs":0,"nbRetries":0,"nonce":167,"slackHook":null,"userAwsFolder":"userAws"}}', headers: {})

    stub_request(:get, "https://phantombuster.s3.amazonaws.com/userAws/awsfoldertest/database-linkedin-network-booster.csv").to_return(
      status: 200, body: File.read('fixtures/csvs/search-3-results.csv'),
    )

    last_pb_args = nil
    stub_request(:post, "https://api.phantombuster.com/api/v2/agents/save").
      with(body: hash_including("org": "user-org-26621", "script": "LLG_DEV.js", "branch": "master", environment: "staging", name: "Campaign Name (D)", id: campaign.phantombuster_agent_id),
           headers: {
             'Accept' => '*/*',
             'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
             'Content-Type' => 'application/json',
             'User-Agent' => 'Ruby',
             'X-Phantombuster-Key' => 'Y6VpQGeuDMf2AoPYSgURiUmuVeZd6aWL',
           }).
      to_return(
        status: 200,
        body: lambda{ |request|
          last_pb_args = JSON.parse(JSON.parse(request.body)["argument"])
          "{\"id\": #{campaign.phantombuster_agent_id}}"
        }, headers: {}
      )

    campaign.update!(should_save_to_phantombuster: true, manual_control: false, message: "foobar")
    expect(last_pb_args["dailyRequestTarget"]).to eq(60)
    expect(last_pb_args["peopleCountToKeep"]).to eq(3000)

    allow(LinkedInLimits).to receive(:save_daily_requests).and_return(12)
    allow(LinkedInLimits).to receive(:people_count_to_keep).and_return(120)


    Campaign::PhantombusterSync.perform_now(campaign)

    expect(last_pb_args["dailyRequestTarget"]).to eq(12)
    expect(last_pb_args["peopleCountToKeep"]).to eq(120)

    campaign.update!(
      manual_control: true,
      manual_daily_request_target: 18,
      manual_people_count_to_keep: 400,
    )
    expect(last_pb_args["dailyRequestTarget"]).to eq(18)
    expect(last_pb_args["peopleCountToKeep"]).to eq(400)

    campaign.update!(
      manual_control: false,
    )
    expect(last_pb_args["dailyRequestTarget"]).to eq(12)
    expect(last_pb_args["peopleCountToKeep"]).to eq(120)
  end

  it "can sync with phantombuster when prospects from a sales navigator search have been assigned to this campaign, it handles the url conversion" do
    campaign = create(:campaign_belonging_to_prospect_pool, company: create(:company_with_prospect_pool))
    company = campaign.company
    search = create(:search, company: company)
    campaign.campaign_search_associations.create!(search: search)
    stub_request(:get, "https://phantombuster.s3.amazonaws.com/userAws/awsfoldertest/some-search.csv").to_return(
      status: 200, body: File.read('fixtures/csvs/search-to-calvin-llg-results-1.csv')
    )
    Search::SearchResultSync.perform_now(search)

    company.distribute_prospects_to_campaigns_idempotently
    expect(company.prospects.all.size).to eq(9)
    expect(campaign.reload.prospects.all.size).to eq(9)

    verify_sync(campaign: campaign, prospect_size: 9)

    uncontacted = campaign.prospects.where(name: "Alfred Uncontacted").first
    expect(uncontacted.vmid).to eq("ACwAAAxqa8YBBw7bTPlhTbDA_clYAGd489S_cc8")
    expect(uncontacted.linked_in_outreach(campaign)).to eq(nil)
  end

  it "can sync with phantombuster if prospects have not been added to the campaign, the prospects will be added automatically" do
    campaign = create(:campaign)
    verify_sync(campaign: campaign)
  end

  it "can return unused_prospects" do
    campaign = create(:campaign)
    campaign2 = create(:campaign)
    expect(campaign.unused_prospects.to_a).to match_array([])
    prospect1 = campaign2.add_prospect!(name: "Calvin Claus", linked_in_profile_url: "https://www.linkedin.com/in/calvinclaus/")
    prospect2 = campaign.add_prospect!(name: "Patrick Blaha", linked_in_profile_url: "https://www.linkedin.com/in/patrick/")
    prospect1.prospect_campaign_associations.create!(campaign: campaign)
    expect(campaign.unused_prospects.to_a).to match_array([prospect1, prospect2])
    prospect1.prospect_campaign_associations.where(campaign: campaign).first.linked_in_outreaches.create!(sent_connection_request_at: DateTime.new)
    expect(campaign.unused_prospects.to_a).to match_array([prospect2])
  end

  def verify_sync(campaign: nil, prospect_size: 8)
    company = campaign.company


    stub_request(:get, "https://phantombuster.com/api/v1/agent/144053").
      with(headers: {'X-Phantombuster-Key-1' => 'Y6VpQGeuDMf2AoPYSgURiUmuVeZd6aWL'}).
      to_return(status: 200, body: '{"status":"success","data":{"id":144053,"name":"LLG_DEV / Patrick Wind LLG","scriptId":20699,"proxy":"none","proxyAddress":null,"proxyUsername":null,"proxyPassword":null,"disableWebSecurity":true,"ignoreSslErrors":true,"loadImages":true,"launch":"manually","nbLaunches":77,"showDebug":true,"awsFolder":"awsfoldertest","executionTimeLimit":10,"fileMgmt":"mix","fileMgmtMaxFolders":5,"lastEndMessage":"Agent finished (success)","lastEndStatus":"success","maxParallelExecs":0,"nbRetries":0,"nonce":167,"slackHook":null,"userAwsFolder":"userAws"}}', headers: {})

    stub_request(:get, "https://phantombuster.s3.amazonaws.com/userAws/awsfoldertest/database-linkedin-network-booster.csv").to_return(
      {status: 200, body: File.read('fixtures/csvs/calvin-llg-results-1.csv')},
      {status: 200, body: File.read('fixtures/csvs/calvin-llg-results-1.csv')},
      {status: 200, body: File.read('fixtures/csvs/calvin-llg-results-1.csv')},
      status: 200, body: File.read('fixtures/csvs/calvin-llg-results-2.csv'),
    )

    # no matter how often we call, the result remains the same with unchanged csv data
    (1..3).each do |_i|
      Campaign::PhantombusterSync.perform_now(campaign)
      company.reload

      expect(company.prospects.all.size).to eq(prospect_size)
      expect(campaign.prospects.all.size).to eq(prospect_size)
      expect(company.credits_left_cache).to eq(-company.prospects.used.size)

      prospect = company.prospects.first
      expect(prospect.name).to eq("Niko Rustemeyer")
      expect(prospect.linked_in_profile_url).to eq("https://www.linkedin.com/in/niko-rustemeyer-a534b729/") # trailing slash added even though csv doesnt have
      expect(prospect.linked_in_profile_url_from_search).to eq("https://www.linkedin.com/sales/people/ACwAAAXycB8B5wfHohYI20i81vwgFuRBa3qdlHk,NAME_SEARCH,sTOm?_ntb=nxHKLk6CQdGR1LLRvcJlrg%3D%3D")
      expect(prospect.vmid).to eq("ACwAAAXycB8B5wfHohYI20i81vwgFuRBa3qdlHk")
      outreach = prospect.linked_in_outreach(campaign)
      expect(outreach.connection_message).to include("Hey Niko,\n")
      expect(outreach.sent_connection_request_at).to eq(DateTime.parse('2019-07-08T17:25:33.223Z'))
      expect(outreach.follow_up_messages).to eq([])
      expect(outreach.follow_up_stage_at_time_of_reply).to eq(nil)

      prospect = company.prospects.where(name: "Arthur Farmer").first
      expect(prospect.name).to eq("Arthur Farmer")
      outreach = prospect.linked_in_outreach(campaign)
      expect(outreach.connection_message).to include("Hey Arthur,\n")
      expect(outreach.accepted_connection_request_at).to eq(DateTime.parse('2019-07-16T06:28:11.283Z'))
      expect(outreach.replied_at).to eq(DateTime.parse('2019-07-16T15:27:03.948Z'))
      expect(outreach.follow_up_messages).to eq([{"stage" => 1, "message" => "Vielen Dank fürs Verbinden! :) Könnte das Tool nützlich sein?", "sent_timestamp" => "2019-07-16T06:28:14.251Z"}])
      expect(outreach.follow_up_stage_at_time_of_reply).to eq(1)
      expect(outreach.connection_request_error).to eq(nil)

      prospect = company.prospects.where(name: "Benjamin Fischer").first
      outreach = prospect.linked_in_outreach(campaign)
      expect(outreach.connection_request_error).to eq("Already in network")
    end

    # NOTE: THIS IS NOW THE FOURTH REQUEST, SO WE'RE NOW ANSWERING WITH A DIFFERENT CSV!
    Campaign::PhantombusterSync.perform_now(campaign)
    expect(company.prospects.all.size).to eq(prospect_size)
    expect(campaign.prospects.all.size).to eq(prospect_size)

    # update value in the csv and see if changes are reflected
    prospect = company.prospects.first
    expect(prospect.name).to eq("Niko Rustemeyer")
    outreach = prospect.linked_in_outreach(campaign)
    expect(outreach.follow_up_stage_at_time_of_reply).to eq(0)
    expect(outreach.replied_at).to eq(DateTime.parse('2019-07-11T10:28:40.090Z'))

    # this csv also deleted the row "Arthur Farmer", but his data should still be present
    prospect = company.prospects.where(name: "Arthur Farmer").first
    expect(prospect.name).to eq("Arthur Farmer")
    outreach = prospect.linked_in_outreach(campaign)
    expect(outreach.connection_message).to include("Hey Arthur,\n")
  end

  it "knows which campaigns used what search" do
    campaign = create(:campaign, name: "Campaign 1")
    search = campaign.company.searches.create!(name: "search name", search_result_csv_url: "foo.com/slash.csv")

    p1 = campaign.add_prospect!(linked_in_profile_url: "foo1")
    p1_assoc = p1.prospect_campaign_associations.first
    p1_assoc.linked_in_outreaches.create!(sent_connection_request_at: Time.at(0))
    p1.prospect_search_associations.create!(search: search, through_query: "query1")

    campaign2 = create(:campaign, name: "Campaign 2")
    p1_assoc2 = campaign2.prospect_campaign_associations.create!(prospect: p1)
    outreach = p1_assoc2.linked_in_outreaches.create!(sent_connection_request_at: Time.at(1))
    outreach.update!(accepted_connection_request_at: Time.at(2))

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

    expect(Campaign.used_search(search).to_a).to match_array([campaign, campaign2])
    expect(Campaign.used_search(search_unrelated).to_a).to match_array([campaign3])
  end

  it "can mark unknown genders" do
    campaign = create(:campaign, name: "Campaign 1", message: "#llgSaluteGeehrt# blah blah")
    p1 = campaign.add_prospect!(linked_in_profile_url: "prospect1", name: "Usksjsndj Jkjhdks")
    p2 = campaign.add_prospect!(linked_in_profile_url: "prospect2", name: "Calvin Claus")

    expect(campaign.next_prospects.to_a).to match_array([p1, p2])
    campaign.compute_cache_columns
    expect(campaign.num_prospects).to eq(2)
    expect(campaign.num_gender_unknown).to eq(0)

    VCR.turn_on!
    VCR.use_cassette("gender_api", record: :new_episodes) do
      Campaign.mark_unknown_genders_for_next_prospects_in_all_campaigns
    end

    expect(campaign.next_prospects.to_a).to match_array([p2])

    campaign.compute_cache_columns
    expect(campaign.num_prospects).to eq(1)
    expect(campaign.num_gender_unknown).to eq(1)
  end

  it "won't mark unknown genders if the message doesn't require it" do
    campaign = create(:campaign, name: "Campaign 1", message: "blah blah")
    p1 = campaign.add_prospect!(linked_in_profile_url: "prospect1", name: "Usksjsndj Jkjhdks")
    p2 = campaign.add_prospect!(linked_in_profile_url: "prospect2", name: "Calvin Claus")

    expect(campaign.next_prospects.to_a).to match_array([p1, p2])
    campaign.compute_cache_columns
    expect(campaign.num_prospects).to eq(2)
    expect(campaign.num_gender_unknown).to eq(0)

    Campaign.mark_unknown_genders_for_next_prospects_in_all_campaigns

    expect(campaign.next_prospects.to_a).to match_array([p1, p2])
    campaign.compute_cache_columns
    expect(campaign.num_prospects).to eq(2)
    expect(campaign.num_gender_unknown).to eq(0)
  end

  it "will mark unknown genders if the message requires it, but ignore the mark if the message no longer contains a gendered salute " do
    campaign = create(:campaign, name: "Campaign 1", message: "#llgSaluteGeehrt# blah blah")
    p1 = campaign.add_prospect!(linked_in_profile_url: "prospect1", name: "Usksjsndj Jkjhdks")
    p2 = campaign.add_prospect!(linked_in_profile_url: "prospect2", name: "Calvin Claus")

    expect(campaign.next_prospects.to_a).to match_array([p1, p2])
    campaign.compute_cache_columns
    expect(campaign.num_prospects).to eq(2)
    expect(campaign.num_gender_unknown).to eq(0)

    VCR.turn_on!
    VCR.use_cassette("gender_api", record: :new_episodes) do
      Campaign.mark_unknown_genders_for_next_prospects_in_all_campaigns
    end

    expect(campaign.next_prospects.to_a).to match_array([p2])
    campaign.compute_cache_columns
    expect(campaign.num_prospects).to eq(1)
    expect(campaign.num_gender_unknown).to eq(1)

    campaign.update!(message: "blah blah")

    expect(campaign.next_prospects.to_a).to match_array([p1, p2])
    campaign.compute_cache_columns
    expect(campaign.num_prospects).to eq(2)
    expect(campaign.num_gender_unknown).to eq(0)

    Campaign.mark_unknown_genders_for_next_prospects_in_all_campaigns
    expect(campaign.next_prospects.to_a).to match_array([p1, p2])
    campaign.compute_cache_columns
    expect(campaign.num_prospects).to eq(2)
    expect(campaign.num_gender_unknown).to eq(0)
  end
end
