require 'rails_helper'

RSpec.feature 'Resllers' do
  scenario "Admins can set a company to be a reseller of n other companies, allowing the reseller to see all the campaigns of the resold companies", :js do
    login_as(create(:unlocked_admin), scope: :admin)

    reseller = create(:company, name: "Reseller")
    reseller_user = create(:user, company: reseller)
    create(:campaign, company: reseller, name: "Reseller Campaign 1")

    resold_c1 = create(:company, name: "Resold 1")
    resold_c1_u = create(:user, company: resold_c1)
    create(:campaign, company: resold_c1, name: "Resold 1 Campaign 1")
    create(:campaign, company: resold_c1, name: "Resold 1 Campaign 2")
    create(:user, company: resold_c1)

    resold_c2 = create(:company, name: "Resold 2")
    create(:campaign, company: resold_c2, name: "Resold 2 Campaign 1")

    non_resold_c = create(:company, name: "Independent 1")
    non_resold_u = create(:user, company: non_resold_c)
    create(:campaign, company: non_resold_c, name: "Independent 1 Campaign 1")

    login_as(reseller_user, scope: :user)
    visit frontend_root_path

    expect(page).to have_text("Reseller Campaign 1")
    expect(page).to_not have_text("Resold 1 Campaign 1")
    expect(page).to_not have_text("Independent 1 Campaign 1")


    visit backend_root_path
    click_on "Companies"

    within find("tr", text: "Reseller") do
      click_on "Edit"
    end

    select "Resold 1", from: "Reseller of"
    select "Resold 2", from: "Reseller of"
    click_on "Update"

    expect(page).to have_text("Passt")

    click_on "Back"

    within find("tr", text: "Resold 2") do
      click_on "Edit"
    end
    expect(page).to have_text("Resold by: Reseller")

    visit frontend_root_path
    expect(page).to have_text("Reseller Campaign 1")
    expect(page).to have_text("Resold 1 Campaign 1")
    expect(page).to have_text("Resold 1 Campaign 2")
    expect(page).to have_text("Resold 2 Campaign 1")
    expect(page).to_not have_text("Independent 1 Campaign 1")

    click_on "Log Out"
    fill_in "Email", with: non_resold_u.email
    fill_in "Password", with: "dev1234"
    click_on "Log in"

    expect(page).to have_text("Independent 1 Campaign 1")
    expect(page).to_not have_text("Reseller Campaign 1")
    expect(page).to_not have_text("Resold 1 Campaign 1")

    click_on "Log Out"
    fill_in "Email", with: resold_c1_u.email
    fill_in "Password", with: "dev1234"
    click_on "Log in"
    expect(page).to have_text("Resold 1 Campaign 1")
    expect(page).to have_text("Resold 1 Campaign 2")
    expect(page).to_not have_text("Resold 2 Campaign 1")
    expect(page).to_not have_text("Reseller Campaign 1")
  end
end
