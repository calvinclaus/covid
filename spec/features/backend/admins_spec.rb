require 'rails_helper'

RSpec.feature 'Admins Devise Integration and Unlocking' do
  scenario "Happy Path: Sign Up, Log Out, Sign In, Password Reset, Unlocking of Account by different Admin" do
    # Admin Sign Up
    visit backend_root_path
    click_on "Register"
    within 'form#new_admin' do
      fill_in "Email", with: "foo@bar.com"
      fill_in "Password", with: "password"
      fill_in "Password confirmation", with: "password"
      click_on "Sign up"
    end
    expect(page).to have_text("Welcome")
    expect(page).to have_text("Log Out")

    # Log Out
    click_on "Log Out"
    expect(page).to have_text("Signed out successfully")
    expect(page).to_not have_text("Log Out")

    # Sign In
    click_on "Log In"
    within 'form#new_admin' do
      fill_in "Email", with: "foo@bar.com"
      fill_in "Password", with: "password"
      click_on "Log in"
    end
    expect(page).to have_text("Signed in successfully.")
    expect(page).to have_text("Log Out")

    # Password Reset
    click_on "Log Out"
    click_on "Log In"
    click_on "Forgot your password?"
    expect(page).to have_text("Forgot your password?")

    within 'form#new_admin' do
      fill_in "Email", with: "foo@bar.com"
      click_on "Send me reset password instructions"
    end

    expect(page).to have_text("You will receive an email with instructions on how to reset your password in a few minutes.")

    expect(ActionMailer::Base.deliveries.size).to eq(1)
    visit ActionMailer::Base.deliveries.first.body.raw_source.match(/href="(?<url>.+?)">/)[:url]

    expect(page).to have_text("Change your password")
    within 'form#new_admin' do
      fill_in "New password", with: "password2"
      fill_in "Confirm new password", with: "password2"
      click_on "Change my password"
    end
    expect(page).to have_text("Your password has been set successfully. You are now signed in.")
    expect(page).to have_text("Log Out")

    # Cannot access anything until unlocked
    click_on "Admins"
    expect(page).to have_text("Ask an admin to unlock your profile first.")
    click_on "Users"
    expect(page).to have_text("Ask an admin to unlock your profile first.")
    click_on "Create User"
    expect(page).to have_text("Ask an admin to unlock your profile first.")

    create(:unlocked_admin)

    click_on "Log Out"
    within 'form#new_admin' do
      fill_in "Email", with: "unlocked@admin.com"
      fill_in "Password", with: "dev1234"
      click_on "Log in"
    end
    click_on "Admins"
    within "[data-test-id=admin-row-foo]" do
      click_on "Edit"
    end
    check "Unlocked"
    click_on "Update Admin"
    expect(page).to have_text("Changes saved successfully")

    click_on "Log Out"

    within 'form#new_admin' do
      fill_in "Email", with: "foo@bar.com"
      fill_in "Password", with: "password2"
      click_on "Log in"
    end

    click_on "Admins"
    expect(page).to have_text("Email")
    expect(page).to have_text("Created")
    expect(page).to have_text("unlocked@admin.com")
  end
end
