require 'rails_helper'

RSpec.describe "Prospect" do
  it "can find duplicate assigned prospects within ProspectPool" do
    models = campaigns_with_assigned_unassigned_prospects

    expect(models.company.prospects.assigned_to_multiple_campaigns_within_pool(models.prospect_pool).to_a).to match_array([models.assigned_twice])

    models.assigned_once.prospect_campaign_associations.create!(campaign: models.campaign2)

    expect(models.company.prospects.assigned_to_multiple_campaigns_within_pool(models.prospect_pool).to_a).to match_array([models.assigned_once, models.assigned_twice])
  end

  it "knows unused prospects" do
    user = create(:user)
    campaign = create(:campaign, company: user.company)
    prospect1 = campaign.add_prospect!(
      linked_in_profile_url: "https://www.linkedin.com/sales/people/one",
    )
    prospect2 = campaign.add_prospect!(
      linked_in_profile_url: "https://www.linkedin.com/sales/people/two",
    )

    _unrelated_prospect = create(:campaign, company: user.company).add_prospect!(linked_in_profile_url: "https://www.linkedin.com/sales/people/unrelated")

    expect(campaign.prospects.unused.to_a).to match_array([prospect1, prospect2])

    prospect1.prospect_campaign_associations.where(campaign: campaign).first.linked_in_outreaches.create!(sent_connection_request_at: DateTime.now)

    expect(campaign.prospects.unused.to_a).to match_array([prospect2])
  end

  it "knows unused prospect_campaign_associations" do
    user = create(:user)
    campaign = create(:campaign, company: user.company)

    assoc1 = campaign.add_prospect!(
      linked_in_profile_url: "https://www.linkedin.com/sales/people/one",
    ).prospect_campaign_associations.first

    assoc2 = campaign.add_prospect!(
      linked_in_profile_url: "https://www.linkedin.com/sales/people/two",
    ).prospect_campaign_associations.first

    _unrelated_prospect = create(:campaign, company: user.company).add_prospect!(linked_in_profile_url: "https://www.linkedin.com/sales/people/unrelated")

    expect(campaign.unused_prospect_campaign_associations.to_a).to match_array([assoc1, assoc2])

    assoc1.linked_in_outreaches.create!(sent_connection_request_at: DateTime.now)

    expect(campaign.unused_prospect_campaign_associations.to_a).to match_array([assoc2])
  end

  def campaigns_with_assigned_unassigned_prospects
    company = create(:user, company: create(:company_with_prospect_pool)).company
    campaign1 = create(:campaign_belonging_to_prospect_pool, company: company, name: "Campaign 1")
    campaign2 = create(:campaign_belonging_to_prospect_pool, company: company, name: "Campaign 2")

    assigned_twice = campaign1.add_prospect!(
      linked_in_profile_url: "https://www.linkedin.com/sales/people/twice",
    )

    assigned_once = campaign1.add_prospect!(
      linked_in_profile_url: "https://www.linkedin.com/sales/people/once",
    )

    assigned_twice.prospect_campaign_associations.create!(campaign: campaign2)

    unassigned = create(:campaign, company: company).add_prospect!(linked_in_profile_url: "https://www.linkedin.com/sales/people/unrelated")

    OpenStruct.new(company: company, prospect_pool: company.prospect_pools.first, campaign1: campaign1, campaign2: campaign2, assigned_twice: assigned_twice, assigned_once: assigned_once, unassigned: unassigned)
  end
end
