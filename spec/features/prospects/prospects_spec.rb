require 'rails_helper'

RSpec.feature 'Campaigns have certain prospects associated with them' do
  scenario "Searches can be added to a campaign" do
    login_as(create(:unlocked_admin), scope: :admin)
    visit backend_root_path

    user = create(:user)
    search = create(:search, company: user.company)
    stub_request(:get, "https://phantombuster.s3.amazonaws.com/userAws/awsfoldertest/some-search.csv").to_return(status: 200, body: File.read('fixtures/csvs/search-1.csv'))
    Search::SearchResultSync.perform_now(search)

    # TODO choose the searches to include in a campaign
    visit edit_backend_company_path(user.company)
  end
end
