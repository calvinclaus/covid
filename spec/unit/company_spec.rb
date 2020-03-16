require 'rails_helper'

RSpec.describe "Company Spec" do
  it "can count credit usage" do
    company = create(:company)
    campaign1 = create(:campaign, company: company)
    campaign2 = create(:campaign, company: company)

    expect(company.used_credits).to eq(0)

    p = campaign1.add_prospect!(linked_in_profile_url: "/some1")
    assoc1_1 = p.prospect_campaign_associations.first.linked_in_outreaches.create!

    p = campaign2.add_prospect!(linked_in_profile_url: "/some2")
    assoc2_1 = p.prospect_campaign_associations.first.linked_in_outreaches.create!
    p = campaign2.add_prospect!(linked_in_profile_url: "/some3")
    assoc2_2 = p.prospect_campaign_associations.first.linked_in_outreaches.create!

    expect(company.used_credits).to eq(3)

    campaign2.update!(follow_up_stages_to_count_as_credit_use: ['2'])

    expect(company.reload.used_credits).to eq(3)

    assoc1_1.update!(follow_up_messages: [
      {"stage": 1, "message": "Vielen Dank fürs Verbinden! :) Könnte das Tool nützlich sein?", "sent_timestamp": "2019-07-16T06:28:14.251Z"},
    ])
    assoc2_1.update!(follow_up_messages: [
      {"stage": 1, "message": "Vielen Dank fürs Verbinden! :) Könnte das Tool nützlich sein?", "sent_timestamp": "2019-07-16T06:28:14.251Z"},
    ])
    assoc2_2.update!(follow_up_messages: [
      {"stage": 1, "message": "Vielen Dank fürs Verbinden! :) Könnte das Tool nützlich sein?", "sent_timestamp": "2019-07-16T06:28:14.251Z"},
    ])
    expect(company.reload.used_credits).to eq(3)

    assoc1_1.update!(follow_up_messages: [
      {"stage": 1, "message": "Vielen Dank fürs Verbinden! :) Könnte das Tool nützlich sein?", "sent_timestamp": "2019-07-16T06:28:14.251Z"},
      {"stage": 2, "message": "Vielen Dank fürs Verbinden! :) Könnte das Tool nützlich sein?", "sent_timestamp": "2019-07-16T06:28:14.251Z"},
    ])

    assoc2_1.update!(follow_up_messages: [
      {"stage": 1, "message": "Vielen Dank fürs Verbinden! :) Könnte das Tool nützlich sein?", "sent_timestamp": "2019-07-16T06:28:14.251Z"},
      {"stage": 2, "message": "Vielen Dank fürs Verbinden! :) Könnte das Tool nützlich sein?", "sent_timestamp": "2019-07-16T06:28:14.251Z"},
    ])

    expect(company.reload.used_credits).to eq(4)

    assoc2_1.update!(follow_up_messages: [
      {"stage": 1, "message": "Vielen Dank fürs Verbinden! :) Könnte das Tool nützlich sein?", "sent_timestamp": "2019-07-16T06:28:14.251Z"},
      {"stage": 2, "message": "Vielen Dank fürs Verbinden! :) Könnte das Tool nützlich sein?", "sent_timestamp": "2019-07-16T06:28:14.251Z"},
      {"stage": 3, "message": "Vielen Dank fürs Verbinden! :) Könnte das Tool nützlich sein?", "sent_timestamp": "2019-07-16T06:28:14.251Z"},
    ])
    assoc2_2.update!(follow_up_messages: [
      {"stage": 1, "message": "Vielen Dank fürs Verbinden! :) Könnte das Tool nützlich sein?", "sent_timestamp": "2019-07-16T06:28:14.251Z"},
      {"stage": 2, "message": "Vielen Dank fürs Verbinden! :) Könnte das Tool nützlich sein?", "sent_timestamp": "2019-07-16T06:28:14.251Z"},
    ])

    expect(company.reload.used_credits).to eq(5)

    campaign2.update!(follow_up_stages_to_count_as_credit_use: ['2', '3'])

    expect(company.reload.used_credits).to eq(6)

    campaign2.update!(follow_up_stages_to_count_as_credit_use: ['3'])

    expect(company.reload.used_credits).to eq(4)
  end

  it "can alert about credits running out" do
    Company.send_credits_left_alert
    expect(ActionMailer::Base.deliveries.count).to eq(0)
    company = create(:company)
    campaign = create(:campaign, company: company)
    expect(company.total_credits).to eq(0)
    expect(company.used_credits).to eq(0)

    company.credit_bookings.create!(name: "Init", credit_amount: 600, booking_date: DateTime.now)

    expect(company.total_credits).to eq(600)

    (1..349).each do |i|
      p = campaign.add_prospect!(linked_in_profile_url: "/some#{i}")
      p.prospect_campaign_associations.first.linked_in_outreaches.create!
    end

    expect(company.reload.used_credits).to eq(349)
    Company.send_credits_left_alert
    expect(ActionMailer::Base.deliveries.count).to eq(0)
    p = campaign.add_prospect!(linked_in_profile_url: "/somex")
    p.prospect_campaign_associations.first.linked_in_outreaches.create!
    expect(company.reload.used_credits).to eq(350)
    Company.send_credits_left_alert
    expect(ActionMailer::Base.deliveries.count).to eq(1)
    p = campaign.add_prospect!(linked_in_profile_url: "/somey")
    p.prospect_campaign_associations.first.linked_in_outreaches.create!

    Company.send_credits_left_alert # doesnt send more than once
    expect(ActionMailer::Base.deliveries.count).to eq(1)

    company.credit_bookings.create!(name: "New", credit_amount: 100, booking_date: DateTime.now)
    expect(company.total_credits).to eq(700)
    Company.send_credits_left_alert # doesnt send more than once
    expect(ActionMailer::Base.deliveries.count).to eq(1)
    p = campaign.add_prospect!(linked_in_profile_url: "/somez")
    p.prospect_campaign_associations.first.linked_in_outreaches.create!
    Company.send_credits_left_alert # doesnt send more than once
    expect(ActionMailer::Base.deliveries.count).to eq(1)
    expect(company.reload.used_credits).to eq(352)

    (352..451).each do |i|
      p = campaign.add_prospect!(linked_in_profile_url: "/some#{i}")
      p.prospect_campaign_associations.first.linked_in_outreaches.create!
    end
    expect(company.reload.used_credits).to eq(452)
    Company.send_credits_left_alert # doesnt send more than once
    expect(ActionMailer::Base.deliveries.count).to eq(2)
    expect(ActionMailer::Base.deliveries.first.subject).to eq("Peter Co. credits almost empty.")
  end
end
