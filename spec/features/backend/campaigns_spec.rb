require 'rails_helper'

RSpec.feature 'Campaigns can be created', :js do
  scenario "If no pb agent can be created displays error in frontend" do
    VCR.turn_off!
    login_as(create(:unlocked_admin), scope: :admin)
    visit backend_root_path

    user = create(:user)

    click_on "Users"
    click_on user.company.name.to_s

    click_on "Add LLG"

    within "[data-test-id=campaign-form]" do
      within "[data-test-id=campaign-name]" do
        fill_in "name", with: "Campaign Name"
      end
      find("[data-test-id=add-linked-in-account]").click
      within "[data-test-id=new-linked-in-account]" do
        fill_in "name", with: "Peter Pan"
        fill_in "liAt", with: "foobar"
        fill_in "email", with: "yo@mama.com"
      end

      within "[data-test-id=connection-message]" do
        fill_in "message", with: "connection message"
      end

      within "[data-test-id=follow-up-0]" do
        fill_in "message", with: "follow up uno"
      end

      find("[name=shouldSaveToPhantombuster]", visible: false).sibling("label").click
      click_on "Save"

      # mock phantombuster api request
      stub_request(:post, "https://api.phantombuster.com/api/v2/agents/save").
        with(body: hash_including("org": "user-org-26621", "script": "LLG_DEV.js", "branch": "master", environment: "staging", name: "Campaign Name (D)", id: ""),
             headers: {
               'Accept' => '*/*',
               'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
               'Content-Type' => 'application/json',
               'User-Agent' => 'Ruby',
               'X-Phantombuster-Key' => 'Y6VpQGeuDMf2AoPYSgURiUmuVeZd6aWL',
             }).
        to_return(status: 200, body: '{ "status": "error", "error": "Your current plan allows for a maximum of 120 Phantoms, a limit that you\'ve reached. You can either: upgrade to another plan, delete a Phantom or contact us at support@phantombuster.com" }', headers: {})
    end

    expect(page).to have_text("Passt")
    expect(page).to_not have_text("Link to PB")
    expect(page).to have_text("No more campaign slots available. Contact calvin@motion-group.com.")
  end

  scenario "Happy Path: Can create a campaign. Will create PB Agent if id blank." do
    page.driver.browser.manage.window.resize_to(1200, 8000)
    VCR.turn_off!
    # mock phantombuster api request
    stub_request(:post, "https://api.phantombuster.com/api/v2/agents/save").
      with(body: hash_including("org": "user-org-26621", "script": "LLG_DEV.js", "branch": "master", environment: "staging", name: "Campaign Name (D)", id: ""),
           headers: {
             'Accept' => '*/*',
             'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
             'Content-Type' => 'application/json',
             'User-Agent' => 'Ruby',
             'X-Phantombuster-Key' => 'Y6VpQGeuDMf2AoPYSgURiUmuVeZd6aWL',
           }).
      to_return(status: 200, body: '{"id": 8273271927}', headers: {})

    login_as(create(:unlocked_admin), scope: :admin)
    visit backend_root_path

    user = create(:user)

    click_on "Users"
    click_on user.company.name.to_s

    click_on "Add LLG"

    within "[data-test-id=campaign-form]" do
      within "[data-test-id=campaign-name]" do
        fill_in "name", with: "Campaign Name"
      end
      fill_in "nextMilestone", with: "800"
      find("[data-test-id=add-linked-in-account]").click
      within "[data-test-id=new-linked-in-account]" do
        fill_in "name", with: "Peter Pan"
        fill_in "liAt", with: "foobar"
        fill_in "email", with: "yo@mama.com"
      end
      within "[data-test-id=connection-message]" do
        fill_in "message", with: "connection message"
      end

      within "[data-test-id=follow-up-0]" do
        fill_in "message", with: "follow up uno"
      end
      find("[name=shouldSaveToPhantombuster]", visible: false).sibling("label").click
      click_on "Save"
    end

    expect(page).to have_text("Passt")

    expect(page).to have_text("8273271927")
    expect(page).to have_text("Link to PB")

    campaign = Campaign.where(phantombuster_agent_id: 8273271927).first
    expect(campaign.phantombuster_launch_times.present?).to eq(true)
    expect(campaign.campaign_cache.last_saved_phantombuster_config.present?).to eq(true)

    within "[data-test-id=campaign-form]" do
      fill_in "nextMilestone", with: "1500"
      click_on "Save" # expect no api request
    end




    # within "[data-test-id=campaign-form]" do
    #  sleep(2)
    #  find("[name=manualControl]", visible: false).sibling("label").click
    #  sleep(2)
    #  fill_in "manualDailyRequestTarget", with: "35"
    #  fill_in "manualPeopleCountToKeep", with: "300"
    #  #click_on "Save" # expecting api request
    # end
    # expect(stub2).to have_been_requested.once





    # fill_in "Name", with: "Peter User LLG"
    # fill_in "Next milestone", with: 1500
    # select "Running", from: "Status"
    # select "Peter Co.", from: "Company"

    # click_on "Create Campaign"

    #    expect(page).to have_text("Bledsinn")

    #    click_on "New LinkedIn Account"
    #    within "[data-test-id=new-existing-linked-in-account]" do
    #      fill_in "Name", with: "Account Name"
    #      fill_in "LinkedIn Account Email", with: "foo@example.com"
    #    end

    #    click_on "Create Campaign"

    # TODO uncomment when li_at verification is built in
    # expect(page).to have_text("Bledsinn")

    # within "[data-test-id=new-existing-linked-in-account]" do
    #  expect(page).to have_text "can't be blank"
    #  fill_in "Cookie li_at", with: "fooooobar"
    # end
    # click_on "Create Campaign"

    #    expect(page).to have_text("Passt")


    #    expect(Delayed::Job.all.length).to eq(0)
    #    fill_in "Phantombuster agent", with: "12345"
    #    click_on "Update"
    #    expect(Delayed::Job.all.length).to eq(1)

    #    within ".campaign_name" do
    #      fill_in "Name", with: "Peter User LLG"
    #    end

    #    click_on "Update"
    #    expect(Delayed::Job.all.length).to eq(1)

    #    fill_in "Phantombuster agent", with: "123456"
    #    click_on "Update"
    #    expect(Delayed::Job.all.length).to eq(2)
  end

  scenario "Happy Path: Can create a campaign" do
    login_as(create(:unlocked_admin), scope: :admin)
    create(:linked_in_account)
    visit backend_root_path

    create(:user)

    click_on "Campaigns"
    click_on "new Campaign"

    fill_in "Name", with: "Peter User LLG"
    fill_in "Next milestone", with: 1500
    select "Running", from: "Status"
    fill_in "Phantombuster agent", with: "12345"
    select "Peter Co.", from: "Company"
    select "Peter Pan", from: "Linked in account"

    click_on "Create Campaign"

    expect(page).to have_text("Passt, nehma!")
  end
end
