class CompanyMailerPreview < ActionMailer::Preview
  def credits_almost_empty_mail
    company = Company.create!(name: "Super Firma")
    campaign = company.campaigns.create!(name: "Super campaign", linked_in_account: LinkedInAccount.create!(name: "foo", email: "foo@bar.com", li_at: "123"))

    company.credit_bookings.create!(name: "Init", credit_amount: 250, booking_date: DateTime.now)

    (1..10).each do |i|
      p = campaign.add_prospect!(linked_in_profile_url: "/some#{i}")
      p.prospect_campaign_associations.first.linked_in_outreaches.create!
    end
    CompanyMailer.credits_almost_empty_mail(company)
  end
end
