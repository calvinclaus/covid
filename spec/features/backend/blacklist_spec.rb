require 'rails_helper'

VCR.configure do |config|
  config.cassette_library_dir = "fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.ignore_localhost = true
end

# can request if an array of company names is on the imported blacklist

RSpec.feature 'Can import blacklists' do
  scenario "Importing Blacklist from Google Docs/CSV with duplicate removal" do
    # TODO fix for new UI
    # company = create(:company)

    # login_as(create(:unlocked_admin), scope: :admin)

    # visit backend_root_path
    # click_on "Companies"
    # click_on "View" # there is only one company
    # expect(page).to_not have_text("Recent Blacklist Imports:")
    # expect(page).to_not have_text("WAITING")

    # fill_in "Csv url", with: "https://docs.google.com/spreadsheets/d/1kqCeY_ljXNsI49hxE-A2ebFzh7SXE_pAlVGtUTu2Quo/edit?usp=sharing"
    # click_on "Create Blacklist import"
    # expect(page).to have_text("Passt")
    # expect(page).to have_text("Recent Blacklist Imports:")
    # expect(page).to have_text("WAITING")
    # expect(page).to have_selector('[data-test-id=blacklistItem]', count: 0)
    # expect(Delayed::Job.all.size).to eq(1)
    # expect(company.blacklisted_companies.size).to eq(0)

    # VCR.use_cassette("Blacklist Google Doc") do
    #  Delayed::Job.all.first.invoke_job
    #  Delayed::Job.all.delete_all
    # end
    # company.reload
    # expect(company.blacklisted_companies.size).to eq(2)
    # expect(company.blacklist_imports.size).to eq(1)

    # visit backend_company_path(company) # reload

    # expect(page).to have_selector('[data-test-id=blacklistCompany]', count: 2)
    # expect(page).to have_text("Foobar Gmbh")
    # expect(page).to have_text("Barfoo Gmbh")

    ## importing the same csv again doesnt add new companies
    ## this csv has no header specifiyng "companyName" but first row
    ## company entry is still recognized

    # stub_request(:get, "https://example.com/some-blacklist.csv").to_return(
    #  status: 200, body: File.read('fixtures/csvs/blacklist-1.csv'),
    # )

    # fill_in "Csv url", with: "https://example.com/some-blacklist.csv"
    # click_on "Create Blacklist import"
    # expect(Delayed::Job.all.size).to eq(1)
    # Delayed::Job.all.last.invoke_job
    # company.reload
    ## Only one more blacklisted_companies
    # expect(company.blacklisted_companies.size).to eq(3)
    ## Another import
    # expect(company.blacklist_imports.size).to eq(2)
    # visit backend_company_path(company) # reload
    # expect(page).to have_selector('[data-test-id=blacklistCompany]', count: 3)
    # expect(page).to have_text("Foobar Gmbh")
    # expect(page).to have_text("Barfoo Gmbh")
    # expect(page).to have_text("Another One")
  end
end


# --- low priority
# can delete singular items from blacklist
# can add singular items to blacklist
