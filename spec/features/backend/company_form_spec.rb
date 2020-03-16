require 'rails_helper'

RSpec.feature 'CompanyForm', :js do
  scenario "Can execute searches on phantombuster - does not execute in parallel if same linkedin account used if second search is added at the same time as the first" do
    VCR.turn_off!

    stub_request(:any, %r{130155/launch}).
      with(body: hash_including({})).
      to_return(
        {status: 200, body: {data: {containerId: "container-1"}}.to_json, headers: {'Content-Type': 'application/json'}},
        status: 200, body: {data: {containerId: "container-2"}}.to_json, headers: {'Content-Type': 'application/json'},
      )

    stub_request(:get, "https://phantombuster.com/api/v1/agent/130155/output?containerId=container-1&mode=track&withoutResultObject=true").
      to_return(
        {status: 200, body: {data: {progress: {label: "50 Profiles Found"}, containerStatus: "running"}}.to_json, headers: {'Content-Type': 'application/json'}},
        {status: 200, body: {data: {progress: {label: "100 Profiles Found"}, containerStatus: "running"}}.to_json, headers: {'Content-Type': 'application/json'}},
        status: 200, body: {data: {progress: nil, containerStatus: "not running", output: "fooabr\n(exit code: 0)"}}.to_json, headers: {'Content-Type': 'application/json'},
      )

    stub_request(:get, "https://phantombuster.com/api/v1/agent/130155/output?containerId=container-2&mode=track&withoutResultObject=true").
      to_return(
        {status: 200, body: {data: {progress: {label: "50 Profiles Found"}, containerStatus: "running"}}.to_json, headers: {'Content-Type': 'application/json'}},
        {status: 200, body: {data: {progress: {label: "100 Profiles Found"}, containerStatus: "running"}}.to_json, headers: {'Content-Type': 'application/json'}},
        status: 200, body: {data: {progress: nil, containerStatus: "not running", output: "fooabr\n(exit code: 0)"}}.to_json, headers: {'Content-Type': 'application/json'},
      )

    stub_request(:get, "https://phantombuster.com/api/v1/agent/130155").
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
        {status: 200, body: File.read('fixtures/csvs/search-1.csv')},
        status: 200, body: File.read('fixtures/csvs/search-2.csv')
      )

    login_as(create(:unlocked_admin), scope: :admin)
    visit backend_root_path

    user = create(:user)

    visit backend_company_path(user.company)


    click_on "Add Search"

    within "[data-test-id=search-form]:last-child" do
      fill_in "name", with: "Search 1"
      fill_in "linkedInSearchUrl", with: "query1"
      find("[data-test-id=add-linked-in-account]").click
      fill_in "liAt", with: "foobar"
      fill_in "email", with: "yo@mama.com"
      within "[data-test-id=linked-in-account-name]" do
        fill_in "name", with: "Peter Pan"
      end
    end

    click_on "Add Search"

    within "[data-test-id=search-form]:last-child" do
      fill_in "name", with: "Search 2"
      fill_in "linkedInSearchUrl", with: "query2"
      find("[name=linkedInAccountId]").click
      find("span", text: "Peter Pan").click
    end

    click_on "Save", match: :first

    expect(page).to have_text("Passt - neh'ma!")

    within "[data-test-id=search-form]:nth-last-child(2)" do
      expect(page).to have_text("Status: SEARCH EXECUTION STARTING")
    end

    within "[data-test-id=search-form]:nth-last-child(1)" do
      expect(page).to have_text("Status: WAITING FOR LINKED_IN_ACCOUNT")
    end

    execute_all_jobs
    sleep(1.5)

    within "[data-test-id=search-form]:nth-last-child(2)" do
      expect(page).to have_text("SEARCH EXECUTING (50 Profiles Found)")
    end

    within "[data-test-id=search-form]:last-child" do
      expect(page).to have_text("Status: WAITING FOR LINKED_IN_ACCOUNT")
    end

    execute_all_jobs
    sleep(1)

    within "[data-test-id=search-form]:nth-last-child(2)" do
      expect(page).to have_text("SEARCH EXECUTING (100 Profiles Found)")
    end

    within "[data-test-id=search-form]:last-child" do
      expect(page).to have_text("Status: WAITING FOR LINKED_IN_ACCOUNT")
    end

    execute_all_jobs

    sleep(1)

    within "[data-test-id=search-form]:nth-last-child(2)" do
      expect(page).to have_text("DONE")
      expect(page).to have_text("Total (after blacklist): 8")
    end

    within "[data-test-id=search-form]:last-child" do
      expect(page).to have_text("Status: SEARCH EXECUTING (50 Profiles Found)")
    end

    execute_all_jobs
    sleep(1)

    within "[data-test-id=search-form]:last-child" do
      expect(page).to have_text("Status: SEARCH EXECUTING (100 Profiles Found)")
    end

    execute_all_jobs
    sleep(1)

    within "[data-test-id=search-form]:last-child" do
      expect(page).to have_text("DONE")
      expect(page).to have_text("Total (after blacklist): 8")
    end
  end

  scenario "Can execute searches on phantombuster - does not execute in parallel if same linkedin account used if second search is added as first serach already running" do
    VCR.turn_off!

    stub_request(:any, %r{130155/launch}).
      with(body: hash_including({})).
      to_return(
        {status: 200, body: {data: {containerId: "container-1"}}.to_json, headers: {'Content-Type': 'application/json'}},
        status: 200, body: {data: {containerId: "container-2"}}.to_json, headers: {'Content-Type': 'application/json'},
      )

    stub_request(:get, "https://phantombuster.com/api/v1/agent/130155/output?containerId=container-1&mode=track&withoutResultObject=true").
      to_return(
        {status: 200, body: {data: {progress: {label: "50 Profiles Found"}, containerStatus: "running"}}.to_json, headers: {'Content-Type': 'application/json'}},
        {status: 200, body: {data: {progress: {label: "100 Profiles Found"}, containerStatus: "running"}}.to_json, headers: {'Content-Type': 'application/json'}},
        status: 200, body: {data: {progress: nil, containerStatus: "not running", output: "fooabr\n(exit code: 0)"}}.to_json, headers: {'Content-Type': 'application/json'},
      )

    stub_request(:get, "https://phantombuster.com/api/v1/agent/130155/output?containerId=container-2&mode=track&withoutResultObject=true").
      to_return(
        {status: 200, body: {data: {progress: {label: "50 Profiles Found"}, containerStatus: "running"}}.to_json, headers: {'Content-Type': 'application/json'}},
        {status: 200, body: {data: {progress: {label: "100 Profiles Found"}, containerStatus: "running"}}.to_json, headers: {'Content-Type': 'application/json'}},
        status: 200, body: {data: {progress: nil, containerStatus: "not running", output: "fooabr\n(exit code: 0)"}}.to_json, headers: {'Content-Type': 'application/json'},
      )

    stub_request(:get, "https://phantombuster.com/api/v1/agent/130155").
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
        {status: 200, body: File.read('fixtures/csvs/search-1.csv')},
        status: 200, body: File.read('fixtures/csvs/search-2.csv')
      )

    login_as(create(:unlocked_admin), scope: :admin)
    visit backend_root_path

    user = create(:user)

    visit backend_company_path(user.company)


    click_on "Add Search"

    within "[data-test-id=search-form]:last-child" do
      fill_in "name", with: "Search 1"
      fill_in "linkedInSearchUrl", with: "query1"
      find("[data-test-id=add-linked-in-account]").click
      fill_in "liAt", with: "foobar"
      fill_in "email", with: "yo@mama.com"
      within "[data-test-id=linked-in-account-name]" do
        fill_in "name", with: "Peter Pan"
      end
    end

    click_on "Save", match: :first

    expect(page).to have_text("Passt - neh'ma!")
    within "[data-test-id=search-form]:last-child" do
      expect(page).to have_text("Status: SEARCH EXECUTION STARTING")
    end
    execute_all_jobs
    sleep(1)

    within "[data-test-id=search-form]:last-child" do
      expect(page).to have_text("SEARCH EXECUTING (50 Profiles Found)")
    end

    click_on "Add Search"

    within "[data-test-id=search-form]:last-child" do
      fill_in "name", with: "Search 2"
      fill_in "linkedInSearchUrl", with: "query2"
      find("[name=linkedInAccountId]").click
      find("span", text: "Peter Pan").click
    end

    click_on "Save", match: :first

    expect(page).to have_text("Passt - neh'ma!")

    within "[data-test-id=search-form]:nth-last-child(2)" do
      expect(page).to have_text("SEARCH EXECUTING (50 Profiles Found)")
    end

    within "[data-test-id=search-form]:last-child" do
      expect(page).to have_text("Status: WAITING FOR LINKED_IN_ACCOUNT")
    end

    execute_all_jobs
    sleep(1)

    within "[data-test-id=search-form]:nth-last-child(2)" do
      expect(page).to have_text("SEARCH EXECUTING (100 Profiles Found)")
    end

    within "[data-test-id=search-form]:last-child" do
      expect(page).to have_text("Status: WAITING FOR LINKED_IN_ACCOUNT")
    end

    execute_all_jobs

    sleep(1)

    within "[data-test-id=search-form]:nth-last-child(2)" do
      expect(page).to have_text("DONE")
      expect(page).to have_text("Total (after blacklist): 8")
    end

    within "[data-test-id=search-form]:last-child" do
      expect(page).to have_text("Status: SEARCH EXECUTING (50 Profiles Found)")
    end

    execute_all_jobs
    sleep(1)

    within "[data-test-id=search-form]:last-child" do
      expect(page).to have_text("Status: SEARCH EXECUTING (100 Profiles Found)")
    end

    execute_all_jobs
    sleep(1)

    within "[data-test-id=search-form]:last-child" do
      expect(page).to have_text("DONE")
      expect(page).to have_text("Total (after blacklist): 8")
    end
  end

  scenario "Can execute searches on phantombuster - executes in parallel if not same linkedin account used" do
    VCR.turn_off!

    stub_request(:any, %r{130155/launch}).
      with(body: hash_including({})).
      to_return(
        {status: 200, body: {data: {containerId: "container-1"}}.to_json, headers: {'Content-Type': 'application/json'}},
        status: 200, body: {data: {containerId: "container-2"}}.to_json, headers: {'Content-Type': 'application/json'},
      )

    stub_request(:get, "https://phantombuster.com/api/v1/agent/130155/output?containerId=container-1&mode=track&withoutResultObject=true").
      to_return(
        {status: 200, body: {data: {progress: {label: "50 Profiles Found"}, containerStatus: "running"}}.to_json, headers: {'Content-Type': 'application/json'}},
        {status: 200, body: {data: {progress: {label: "100 Profiles Found"}, containerStatus: "running"}}.to_json, headers: {'Content-Type': 'application/json'}},
        status: 200, body: {data: {progress: nil, containerStatus: "not running", output: "fooabr\n(exit code: 0)"}}.to_json, headers: {'Content-Type': 'application/json'},
      )

    stub_request(:get, "https://phantombuster.com/api/v1/agent/130155/output?containerId=container-2&mode=track&withoutResultObject=true").
      to_return(
        {status: 200, body: {data: {progress: {label: "50 Profiles Found"}, containerStatus: "running"}}.to_json, headers: {'Content-Type': 'application/json'}},
        {status: 200, body: {data: {progress: {label: "100 Profiles Found"}, containerStatus: "running"}}.to_json, headers: {'Content-Type': 'application/json'}},
        status: 200, body: {data: {progress: nil, containerStatus: "not running", output: "fooabr\n(exit code: 0)"}}.to_json, headers: {'Content-Type': 'application/json'},
      )

    stub_request(:get, "https://phantombuster.com/api/v1/agent/130155").
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
        {status: 200, body: File.read('fixtures/csvs/search-1.csv')},
        status: 200, body: File.read('fixtures/csvs/search-2.csv')
      )

    login_as(create(:unlocked_admin), scope: :admin)
    visit backend_root_path

    user = create(:user)

    visit backend_company_path(user.company)


    click_on "Add Search"

    within "[data-test-id=search-form]:last-child" do
      fill_in "name", with: "Search 1"
      fill_in "linkedInSearchUrl", with: "query1"
      find("[data-test-id=add-linked-in-account]").click
      fill_in "liAt", with: "foobar"
      fill_in "email", with: "yo@mama.com"
      within "[data-test-id=linked-in-account-name]" do
        fill_in "name", with: "Peter Pan"
      end
    end


    click_on "Add Search"

    within "[data-test-id=search-form]:last-child" do
      fill_in "name", with: "Search 2"
      fill_in "linkedInSearchUrl", with: "query2"
      find("[data-test-id=add-linked-in-account]").click
      fill_in "liAt", with: "foobar2"
      fill_in "email", with: "yo2@mama.com"
      within "[data-test-id=linked-in-account-name]" do
        fill_in "name", with: "Peter Pan 2"
      end
    end

    click_on "Save", match: :first

    expect(page).to have_text("Passt - neh'ma!")

    within "[data-test-id=search-form]:nth-last-child(2)" do
      expect(page).to have_text("Status: SEARCH EXECUTION STARTING")
    end

    within "[data-test-id=search-form]:last-child" do
      expect(page).to have_text("Status: SEARCH EXECUTION STARTING")
    end

    execute_all_jobs
    sleep(1.5)

    within "[data-test-id=search-form]:nth-last-child(2)" do
      expect(page).to have_text("SEARCH EXECUTING (50 Profiles Found)")
    end

    within "[data-test-id=search-form]:last-child" do
      expect(page).to have_text("SEARCH EXECUTING (50 Profiles Found)")
    end

    execute_all_jobs
    sleep(1)

    within "[data-test-id=search-form]:nth-last-child(2)" do
      expect(page).to have_text("SEARCH EXECUTING (100 Profiles Found)")
    end

    within "[data-test-id=search-form]:last-child" do
      expect(page).to have_text("SEARCH EXECUTING (100 Profiles Found)")
    end

    execute_all_jobs

    sleep(1)

    within "[data-test-id=search-form]:nth-last-child(2)" do
      expect(page).to have_text("DONE")
      expect(page).to have_text("Total (after blacklist): 8")
    end

    within "[data-test-id=search-form]:last-child" do
      expect(page).to have_text("DONE")
      expect(page).to have_text("Total (after blacklist): 8")
    end
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
