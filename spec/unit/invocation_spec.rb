require 'rails_helper'

RSpec.describe "Invocation" do
  it "can find all invocations of a linkedin account" do
    campaign = create(:campaign)
    campaign.invocations.create!

    campaign2 = create(:campaign)
    campaign2.update!(linked_in_account: campaign.linked_in_account)
    campaign2.invocations.create!

    campaign3 = create(:campaign)
    li2 = LinkedInAccount.create!(li_at: "foo", name: "foo", email: "foo@bar.com")
    campaign3.update!(linked_in_account: li2)
    campaign3.invocations.create!

    campaign4 = create(:campaign, script_type: "LM")
    campaign4.update!(linked_in_account: li2)
    campaign4.invocations.create!
    campaign4.invocations.create!

    expect(Invocation.all.size).to eq(5)
    expect(Invocation.llg_invocations_of(campaign.linked_in_account).size).to eq(2)
    expect(Invocation.llg_invocations_of(li2).size).to eq(1)
  end
end
