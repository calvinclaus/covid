require 'rails_helper'

RSpec.describe "Search" do
  it "can remove page num from query" do
    expect(Search.remove_page_num_from_query("foo.com?page=1&bar=foo&page=12&baz=bar&page=100")).to eq("foo.com?bar=foo&baz=bar")
    expect(Search.remove_page_num_from_query("foo.com?page=1")).to eq("foo.com")
    expect(Search.remove_page_num_from_query("foo.com/?page=1&foo=baz")).to eq("foo.com/?foo=baz")
    expect(Search.remove_page_num_from_query("foo.com/?bar=baz&page=100")).to eq("foo.com/?bar=baz")
    expect(Search.remove_page_num_from_query("https://www.linkedin.com/sales/search/people?companySize=D%2CE%2CF%2CG%2CH%2CI&doFetchHeroCard=false&functionIncluded=12&geoIncluded=101282230&logHistory=false&logId=8484183803&page=9&preserveScrollPosition=false&rsLogId=123021857&searchSessionId=%2BtLrGpQVSuG5%2FU%2FhxgUADQ%3D%3D&seniorityIncluded=6%2C7%2C8%2C9&spotlight=RECENTLY_POSTED_ON_LINKEDIN")).to eq("https://www.linkedin.com/sales/search/people?companySize=D%2CE%2CF%2CG%2CH%2CI&doFetchHeroCard=false&functionIncluded=12&geoIncluded=101282230&logHistory=false&logId=8484183803&preserveScrollPosition=false&rsLogId=123021857&searchSessionId=%2BtLrGpQVSuG5%2FU%2FhxgUADQ%3D%3D&seniorityIncluded=6%2C7%2C8%2C9&spotlight=RECENTLY_POSTED_ON_LINKEDIN")
  end

  it "can deal with the same prospect being found by the same search" do
    user = create(:user)
    search = create(:search, company: user.company)

    stub_request(:get, "https://phantombuster.s3.amazonaws.com/userAws/awsfoldertest/some-search.csv").to_return(
      status: 200, body: File.read('fixtures/csvs/search-with-duplicate-prospect.csv'),
    )

    expect(user.company.prospects.all.size).to eq(0)

    Search::SearchResultSync.perform_now(search)

    expect(user.company.prospects.all.size).to eq(1)

    prospect = user.company.prospects.all.first
    expect(prospect.prospect_search_associations.size).to eq(1)
    expect(user.company.prospects.all.first.vmid).to eq("ACwAAAXycB8B5wfHohYI20i81vwgFuRBa3qdlHk")
    expect(prospect.linked_in_profile_url).to eq("https://www.linkedin.com/sales/people/ACwAAAXycB8B5wfHohYI20i81vwgFuRBa3qdlHk,NAME_SEARCH,sTOm?_ntb=from-first-search/")
    expect(prospect.linked_in_profile_url_from_search).to include("https://www.linkedin.com/sales/people/ACwAAAXycB8B5wfHohYI20i81vwgFuRBa3qdlHk,NAME_SEARCH")

    # we could leave this behaviour undefined, it just picks the one further down the csv for now
    expect(prospect.prospect_search_associations.where(search: search).first.through_query).to eq("search_query_2")
  end


  it "can deal with the same prospect being found by two searches and therefore different sales nav urls" do
    user = create(:user)
    search1 = create(:search, company: user.company)
    search2 = create(:search, company: user.company, search_result_csv_url: "https://phantombuster.s3.amazonaws.com/userAws/awsfoldertest/some-search-2.csv")

    stub_request(:get, "https://phantombuster.s3.amazonaws.com/userAws/awsfoldertest/some-search.csv").to_return(
      status: 200, body: File.read('fixtures/csvs/search-3.csv'),
    )
    stub_request(:get, "https://phantombuster.s3.amazonaws.com/userAws/awsfoldertest/some-search-2.csv").to_return(
      status: 200, body: File.read('fixtures/csvs/search-3-same-result-different-sales-nav-url.csv'),
    )

    expect(user.company.prospects.all.size).to eq(0)

    Search::SearchResultSync.perform_now(search1)
    expect(user.company.prospects.all.size).to eq(1)

    prospect = user.company.prospects.all.first
    expect(prospect.prospect_search_associations.size).to eq(1)
    expect(user.company.prospects.all.first.vmid).to eq("ACwAAAXycB8B5wfHohYI20i81vwgFuRBa3qdlHk")
    expect(prospect.linked_in_profile_url).to eq("https://www.linkedin.com/sales/people/ACwAAAXycB8B5wfHohYI20i81vwgFuRBa3qdlHk,NAME_SEARCH,sTOm?_ntb=from-first-search/")
    expect(prospect.linked_in_profile_url_from_search).to eq("https://www.linkedin.com/sales/people/ACwAAAXycB8B5wfHohYI20i81vwgFuRBa3qdlHk,NAME_SEARCH,sTOm?_ntb=from-first-search/")

    Search::SearchResultSync.perform_now(search2)
    prospect.reload
    expect(user.company.prospects.all.size).to eq(1)

    expect(prospect.prospect_search_associations.size).to eq(2)
    expect(user.company.prospects.all.first.vmid).to eq("ACwAAAXycB8B5wfHohYI20i81vwgFuRBa3qdlHk")
    expect(prospect.linked_in_profile_url).to eq("https://www.linkedin.com/sales/people/ACwAAAXycB8B5wfHohYI20i81vwgFuRBa3qdlHk,NAME_SEARCH,sTOm?_ntb=from-first-search/")
    expect(prospect.linked_in_profile_url_from_search).to eq("https://www.linkedin.com/sales/people/ACwAAAXycB8B5wfHohYI20i81vwgFuRBa3qdlHk,NAME_SEARCH,sTOm?_ntb=from-second-search/")

    expect(prospect.prospect_search_associations.where(search: search1).first.through_query).to eq("search_query_1")
    expect(prospect.prospect_search_associations.where(search: search2).first.through_query).to eq("search_query_2")
  end

  it "can sync a non-sales nav csv" do
    search = create(:search)
    stub_request(:get, "https://phantombuster.s3.amazonaws.com/userAws/awsfoldertest/some-search.csv").to_return(
      status: 200, body: File.read('fixtures/csvs/non-sales-nav-search.csv')
    )

    3.times do
      Search::SearchResultSync.perform_now(search)

      expect(search.company.prospects.all.size).to eq(1)
      prospect = search.company.prospects.first
      expect(prospect.linked_in_profile_url).to eq("https://www.linkedin.com/in/mary-funkhouser-9b185a6/")
      expect(prospect.title).to eq("Summary: ...Indep. Affiliate of Gifted Travel Network—a Virtuoso® Member")
      expect(prospect.vmid).to eq(nil)
    end
  end

  it "can sync if no vmid but only linked_in_profile_url already present" do
    user = create(:user)
    search = create(:search, company: user.company)

    campaign = create(:campaign, company: user.company)

    stub_request(:get, "https://phantombuster.com/api/v1/agent/144053").
      with(headers: {'X-Phantombuster-Key-1' => 'Y6VpQGeuDMf2AoPYSgURiUmuVeZd6aWL'}).
      to_return(status: 200, body: '{"status":"success","data":{"id":144053,"name":"LLG_DEV / Patrick Wind LLG","scriptId":20699,"proxy":"none","proxyAddress":null,"proxyUsername":null,"proxyPassword":null,"disableWebSecurity":true,"ignoreSslErrors":true,"loadImages":true,"launch":"manually","nbLaunches":77,"showDebug":true,"awsFolder":"awsfoldertest","executionTimeLimit":10,"fileMgmt":"mix","fileMgmtMaxFolders":5,"lastEndMessage":"Agent finished (success)","lastEndStatus":"success","maxParallelExecs":0,"nbRetries":0,"nonce":167,"slackHook":null,"userAwsFolder":"userAws"}}', headers: {})

    stub_request(:get, "https://phantombuster.s3.amazonaws.com/userAws/awsfoldertest/database-linkedin-network-booster.csv").to_return(status: 200, body: File.read('fixtures/csvs/lm-results-1.csv'),)

    Campaign::PhantombusterSync.perform_now(campaign)


    stub_request(:get, "https://phantombuster.s3.amazonaws.com/userAws/awsfoldertest/some-search.csv").to_return(
      status: 200, body: File.read('fixtures/csvs/lm-search-1.csv'),
    )

    Search::SearchResultSync.perform_now(search)

    expect(search.reload.prospects.size).to eq(1)
  end

  it "can sync phantombuster csv" do
    user = create(:user)
    search = create(:search, company: user.company)

    stub_request(:get, "https://phantombuster.s3.amazonaws.com/userAws/awsfoldertest/some-search.csv").to_return(
      {status: 200, body: File.read('fixtures/csvs/search-1.csv')},
      {status: 200, body: File.read('fixtures/csvs/search-1.csv')},
      {status: 200, body: File.read('fixtures/csvs/search-1.csv')},
      status: 200, body: File.read('fixtures/csvs/search-2.csv'),
    )

    expect(user.company.prospects.all.size).to eq(0)

    # no matter how often we call, the result remains the same with unchanged csv data
    (1..3).each do |_i|
      Search::SearchResultSync.perform_now(search)

      expect(user.company.prospects.all.size).to eq(8)
      expect(search.reload.prospects.all.size).to eq(8) # also associated with search model

      prospect = user.company.prospects.first
      expect(search.prospects.first).to eq(prospect) # also associated with search model
      expect(prospect.name).to eq("Marcus Mayer")
      expect(prospect.linked_in_profile_url).to eq("https://www.linkedin.com/sales/people/ACwAABF2DacBP009Z1ua4o0F9oAlj6j3JudjtTg,NAME_SEARCH,MvTu?_ntb=NPLCX%2B8FTMSbGqrKo%2Bsxvw%3D%3D/") # trailing slash added even though csv doesnt have
      expect(prospect.linked_in_profile_url_from_search).to eq("https://www.linkedin.com/sales/people/ACwAABF2DacBP009Z1ua4o0F9oAlj6j3JudjtTg,NAME_SEARCH,MvTu?_ntb=NPLCX%2B8FTMSbGqrKo%2Bsxvw%3D%3D/")
      expect(prospect.prospect_search_associations.size).to eq(1)
      expect(prospect.prospect_search_associations.first.through_query).to eq("https://www.linkedin.com/sales/search/people?companySize=F%2CG%2CH%2CI&doFetchHeroCard=false&geoIncluded=101282230&industryExcluded=12%2C4%2C41%2C75%2C96&logHistory=true&logId=3476645376&rsLogId=72276884&searchSessionId=NPLCX%2B8FTMSbGqrKo%2Bsxvw%3D%3D&tenureAtCurrentCompany=1&titleIncluded=CTO%3A153%2CChief%2520Digital%2520Officer%2520(CDO)%3A25884%2CCEO%3A8%2CIT-Leiter%3A688%2CCIO%3A203%2CCFO%3A68%2CIT%2520Director%3A163%2CVice%2520President%2520IT%3A747%2CVice%2520President%2520Technologie%3A759%2CIT-Manager%3A65%2CLeitender%2520IT-Manager%3A1054%2CEnterprise%2520Solutions%2520Architect%3A10998&titleTimeScope=CURRENT")
      expect(prospect.prospect_search_associations.first.searched_at).to eq(DateTime.parse("2019-09-16T11:14:03.969Z"))

      expect(prospect.primary_company_name).to eq("Kelvion")
      expect(prospect.primary_company_linkedin_url).to eq("https://www.linkedin.com/company/10297346")
      expect(prospect.company_domains).to eq([])
    end

    # NOTE: THIS IS NOW THE FOURTH REQUEST, SO WE'RE NOW ANSWERING WITH A DIFFERENT CSV!
    Search::SearchResultSync.perform_now(search)

    # new guy added
    expect(user.company.prospects.all.size).to eq(9)
    prospect = user.company.prospects.last
    expect(prospect.name).to eq("Philipp Lübcke")


    # update value in the csv and see if changes are reflected
    prospect = user.company.prospects.first
    expect(prospect.name).to eq("Marcus Mayer")
    expect(prospect.primary_company_linkedin_url).to eq("changed")

    # this csv also deleted the row "Sacha Dannewitz", but his data should still be present
    prospect = user.company.prospects.where(name: "Sacha Dannewitz").first
    expect(prospect.name).to eq("Sacha Dannewitz")
  end

  it "knows what campaigns used a search" do
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
    search2 = campaign3.company.searches.create!(name: "search name", search_result_csv_url: "foo.com/slash.csv")
    p2.prospect_search_associations.create!(search: search2, through_query: "query_unrelated")
    p2.prospect_search_associations.create!(search: search, through_query: "query1")

    expect(Search.used_by_campaign(campaign).to_a).to match_array([search])
    expect(Search.used_by_campaign(campaign2).to_a).to match_array([search])
    expect(Search.used_by_campaign(campaign3).to_a).to match_array([search, search2])
  end
end
