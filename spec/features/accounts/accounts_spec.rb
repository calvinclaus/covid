require 'rails_helper'

RSpec.feature 'Admins and Users can interact with accounts' do
  scenario "Admins can create user accounts. User can set their password. Login. Log Out. Reset their password.", :js do
    login_as(create(:unlocked_admin), scope: :admin)

    visit backend_root_path

    click_on "Create User"

    fill_in "Email", with: "user@email.com"
    fill_in "Name", with: "Peter Pan"
    click_on "Neue Firma Anlegen"
    within("[data-test-id=new-existing-company]") do
      fill_in "Name", with: "Peter Co."
    end
    within("form") do
      click_on "Create User"
    end


    expect(page).to have_text("Passt, nehma!")

    expect(page).to have_text("Peter Co.")
    expect(Company.all.size).to eq(1)
    expect(Company.all.first.name).to eq("Peter Co.")

    click_on "Send Password Creation Instructions"

    expect(page).to have_text("Dem Nutzer wurde eine Email mit Anweisungen zum setzen des Passworts an user@email.com geschickt")

    expect(ActionMailer::Base.deliveries.size).to eq(1)
    expect(ActionMailer::Base.deliveries.first.body.raw_source).to include("Hallo Peter!")
    expect(ActionMailer::Base.deliveries.first.body.raw_source).to include("Wir haben gerade deinen Account mit der Email \"user@email.com\" erstellt.")

    logout(:admin)

    visit ActionMailer::Base.deliveries.first.body.raw_source.match(/href="(?<url>.+?)">/)[:url]

    expect(page).to have_text("Set Password")
    fill_in "Password", with: "password", match: :prefer_exact
    fill_in "Password confirmation", with: "password", match: :prefer_exact
    click_on "Continue"

    expect(page).to have_text("Your password has been set successfully. You are now signed in.")
    expect(page).to have_text("Overview")

    click_on "Log Out"

    fill_in "Email", with: "user@email.com"
    fill_in "Password", with: "password"
    click_on "Log in"

    expect(page).to have_text("Signed in successfully")


    # When resetting normally, the normal reset message is displayed
    click_on "Log Out"
    click_on "Forgot your password"
    fill_in "Email", with: "user@email.com"
    click_on "Send reset password instructions"
    expect(ActionMailer::Base.deliveries.size).to eq(2)
    expect(ActionMailer::Base.deliveries.last.body.raw_source).to include("Hallo Peter!")
    expect(ActionMailer::Base.deliveries.last.body.raw_source).to include("Jemand hat das Zurücksetzen deines Passworts angefordert")
  end
end
