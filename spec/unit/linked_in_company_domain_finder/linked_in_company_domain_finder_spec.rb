require 'rails_helper'


RSpec.describe "LinkedIn Company Domain Finder", linkedin: true do
  it "can deal with all LinkedIn Accounts being logged out" do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    search = search_with_prospects

    logged_out_account = create(:logged_out_linked_in_account, logged_in: true)

    domain_finder = LinkedInCompanyDomainFinder.create!(search: search, linked_in_accounts: [logged_out_account])

    VCR.use_cassette("domain finder can deal with all accounts logged out") do
      expect{ domain_finder.work(skip_sleep: true) }.to raise_error(LinkedInCompanyDomainFinder::AllAccountsLoggedOut)
    end

    deliveries = ActionMailer::Base.deliveries
    pp deliveries.map(&:subject)
    expect(deliveries.size).to eq(1)
    expect(deliveries.first.subject).to include('logged out')
  end

  it "can find company domains and handle some accounts being logged out gracefully" do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    search = search_with_prospects

    logged_out_account = create(:logged_out_linked_in_account, logged_in: true)
    logged_in_account = create(:linked_in_account, logged_in: true)

    domain_finder = LinkedInCompanyDomainFinder.create!(search: search, linked_in_accounts: [logged_in_account, logged_out_account])


    VCR.use_cassette("domain finder can find domains") do
      domain_finder.work(skip_sleep: true)
    end

    prospects = search.prospects
    expect(prospects.first.company_domains.first).to eq("https://www.becon.de/")
    expect(prospects.second.company_domains.first).to eq("https://go.hyve.net/newsletteranmeldung/")
    expect(prospects.third.company_domains.first).to eq("https://b2bmg.net/")
    expect(prospects.fourth.company_domains.first).to eq("https://b2bmg.net/")
    expect(prospects.fifth.company_domains.first).to eq("http://www.hak-imst.ac.at/")
    # TODO test this works if prospect with same company name exists outside of this search

    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to eq(1)
    expect(deliveries.first.subject).to include('logged out')
  end

  def search_with_prospects
    user = create(:user)
    search = create(:search, company: user.company)

    # TODO these could go into a factory

    search.add_prospect!(
      linked_in_profile_url: "https://www.linkedin.com/sales/people/ACwAAApvJtUBh6FCOkI7pm16QkQA0HtP7s4dsL8,NAME_SEARCH,NAAF?_ntb=Lt1A653jQyuWoIe7HaJ3EA%3D%3D",
      linked_in_profile_url_from_search: "https://www.linkedin.com/sales/people/ACwAAApvJtUBh6FCOkI7pm16QkQA0HtP7s4dsL8,NAME_SEARCH,NAAF?_ntb=Lt1A653jQyuWoIe7HaJ3EA%3D%3D",
      primary_company_name: "becon GmbH",
      primary_company_linkedin_url: "https://www.linkedin.com/company/27120250",
    )

    search.add_prospect!(
      linked_in_profile_url: "https://www.linkedin.com/sales/people/ACwAABvTWcYBc8pbVfmtzDzFvH_TcJc3yQMGEE8,NAME_SEARCH,t7Fh?_ntb=Lt1A653jQyuWoIe7HaJ3EA%3D%3D",
      linked_in_profile_url_from_search: "https://www.linkedin.com/sales/people/ACwAABvTWcYBc8pbVfmtzDzFvH_TcJc3yQMGEE8,NAME_SEARCH,t7Fh?_ntb=Lt1A653jQyuWoIe7HaJ3EA%3D%3D",
      primary_company_name: "HYVE - the innovation company",
      primary_company_linkedin_url: "https://www.linkedin.com/company/133969",
    )

    search.add_prospect!(
      linked_in_profile_url: "https://www.linkedin.com/sales/people/ACwAABIDjbkBTJ9i4TIO-PB11RHAypepkSofYtg,NAME_SEARCH,Sj1B?_ntb=Lt1A653jQyuWoIe7HaJ3EA%3D%3D",
      linked_in_profile_url_from_search: "https://www.linkedin.com/sales/people/ACwAABIDjbkBTJ9i4TIO-PB11RHAypepkSofYtg,NAME_SEARCH,Sj1B?_ntb=Lt1A653jQyuWoIe7HaJ3EA%3D%3D",
      primary_company_name: "B2B Media Group",
      primary_company_linkedin_url: "https://www.linkedin.com/company/2663474",
    )

    search.add_prospect!(
      linked_in_profile_url: "https://www.linkedin.com/sales/people/foo-PB11RHAypepkSofYtg,NAME_SEARCH,Sj1B?_ntb=Lt1A653jQyuWoIe7HaJ3EA%3D%3D",
      linked_in_profile_url_from_search: "https://www.linkedin.com/sales/people/foo-PB11RHAypepkSofYtg,NAME_SEARCH,Sj1B?_ntb=Lt1A653jQyuWoIe7HaJ3EA%3D%3D",
      primary_company_name: "B2B Media Group",
      primary_company_linkedin_url: "",
    )

    search.add_prospect!(
      linked_in_profile_url: "https://www.linkedin.com/sales/people/bar-PB11RHAypepkSofYtg,NAME_SEARCH,Sj1B?_ntb=Lt1A653jQyuWoIe7HaJ3EA%3D%3D",
      linked_in_profile_url_from_search: "https://www.linkedin.com/sales/people/bar-PB11RHAypepkSofYtg,NAME_SEARCH,Sj1B?_ntb=Lt1A653jQyuWoIe7HaJ3EA%3D%3D",
      primary_company_name: "Who cares",
      primary_company_linkedin_url: "https://www.linkedin.com/school/hak-has-digbizhak-imst/about/",
    )



    expect(search.prospects.size).to eq(5)
    expect(search.prospects.third.primary_company_linkedin_url).to eq("https://www.linkedin.com/company/2663474")


    search
  end
end
