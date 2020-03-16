require 'rails_helper'

RSpec.feature 'Displays Campaign Statistics', :js do
  scenario "Displays correct statistics and segments" do
    travel_to DateTime.parse("2019-07-21")
    page.driver.browser.manage.window.resize_to(1200, 5200)

    user = create(:user)
    campaign = create(:campaign, company: user.company)


    stub_request(:get, "https://phantombuster.com/api/v1/agent/144053").
      with(headers: {'X-Phantombuster-Key-1' => 'Y6VpQGeuDMf2AoPYSgURiUmuVeZd6aWL'}).
      to_return(status: 200, body: '{"status":"success","data":{"id":144053,"name":"LLG_DEV / Patrick Wind LLG","scriptId":20699,"proxy":"none","proxyAddress":null,"proxyUsername":null,"proxyPassword":null,"disableWebSecurity":true,"ignoreSslErrors":true,"loadImages":true,"launch":"manually","nbLaunches":77,"showDebug":true,"awsFolder":"awsfoldertest","executionTimeLimit":10,"fileMgmt":"mix","fileMgmtMaxFolders":5,"lastEndMessage":"Agent finished (success)","lastEndStatus":"success","maxParallelExecs":0,"nbRetries":0,"nonce":167,"slackHook":null,"userAwsFolder":"userAws"}}', headers: {})

    stub_request(:get, "https://phantombuster.s3.amazonaws.com/userAws/awsfoldertest/database-linkedin-network-booster.csv").to_return(
      status: 200, body: File.read('fixtures/csvs/statistics_spec_1.csv'),
    )

    Campaign::PhantombusterSync.perform_now(campaign)

    login_as(create(:unlocked_admin), scope: :admin)
    visit backend_root_path

    click_on "Campaigns"

    within "[data-test-id=campaign-preview-#{campaign.id}]" do
      expect(page).to have_text("Campaign Name")
      expect(page).to have_css('[aria-label="Requested"]', text: "7")

      expect(page).to have_css('[aria-label="Connected"]', text: "86%")
      expect(page).to have_css('[aria-label="Connected"]', text: "6")

      expect(page).to have_css('[aria-label="Responded"]', text: "83%")


      find('[aria-label="Details"]').click
    end

    within find(".statBox", text: "Requested") do
      expect(page).to have_text("7")
    end

    within find(".statBox", text: "Connected") do
      expect(page).to have_text("86%  6")
    end

    within find(".statBox", text: "Responded") do
      expect(page).to have_text("83%")
      click_on class: "button"
      expect(page).to have_text("60%  3\n  after 1. message")
      expect(page).to have_text("40%  2\n  after 2. message")
    end



    # Testing CACHE - updated_at of Statistic should remain the same:
    stat_updated_at = campaign.statistics.first.updated_at
    travel_to DateTime.parse("2019-07-21") + 1.minutes
    click_on "Campaigns"
    expect(campaign.reload.statistics.first.updated_at).to eq(stat_updated_at)


    find('[aria-label="Edit"]').click

    within('[data-test-id=company-form]') do
      find('[aria-label="Edit"]').click
      within('[data-test-id=campaign-form]') do
        fill_in "Segment Name", with: "Custom Segment Name"
        fill_in "Start Date", with: "2019-07-15"
      end
      find("[data-test-id=campaign-form]").click

      within('[data-test-id=campaign-form]') do
        click_on "Save"
      end
    end

    expect(page).to have_text("Passt")

    visit backend_campaign_path(campaign.id)

    expect(page).to have_text "Segments"

    expect(page).to have_text "Custom Segment Name"

    within find(".statisticListItem", text: "Custom Segment Name") do
      expect(page).to have_css('[aria-label="Requested"]', text: "4")

      expect(page).to have_css('[aria-label="Connected"]', text: "100%")

      expect(page).to have_css('[aria-label="Responded"]', text: "75%")
      expect(page).to have_text("33%  1\n  after 1. message")
      expect(page).to have_text("67%  2\n  after 2. message")
    end

    within find(".statisticListItem", text: "Start") do
      expect(page).to have_css('[aria-label="Requested"]', text: "3")

      expect(page).to have_css('[aria-label="Connected"]', text: "67%  2")

      expect(page).to have_css('[aria-label="Responded"]', text: "100%  2")
      expect(page).to have_text("100%  2\n  after 1. message")
    end
  end
end
