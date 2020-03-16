require 'rails_helper'

RSpec.describe "Prospects Association Logic" do
  it "will keep a prospect that has been contacted by two campaigns associated with both campaigns" do
    # ... doesnt matter how that state was reached. It should generally be allowed.
    # Because the user should be able to change the search config at any time this state can defintely occur
    # i.e. allowing two campaigns to contact the same pleople and then later chaning their mind

    company = create(:user, company: create(:company_with_prospect_pool)).company
    campaign1 = create(:campaign_belonging_to_prospect_pool, company: company, name: "Campaign 1")
    campaign2 = create(:campaign_belonging_to_prospect_pool, company: company, name: "Campaign 2")

    search1 = create(:search, name: "Search 1", company: company)
    search1_prospect1 = search1.add_prospect!(linked_in_profile_url: "https://www.linkedin.com/sales/people/s1")
    search1_prospect2 = search1.add_prospect!(linked_in_profile_url: "https://www.linkedin.com/sales/people/s2")
    search1_prospect3 = search1.add_prospect!(linked_in_profile_url: "https://www.linkedin.com/sales/people/s3")

    prospect_campaign1_assoc = search1_prospect1.prospect_campaign_associations.create!(campaign: campaign1)
    prospect_campaign2_assoc = search1_prospect1.prospect_campaign_associations.create!(campaign: campaign2)

    prospect_campaign1_assoc.linked_in_outreaches.create!(sent_connection_request_at: Date.new)
    prospect_campaign2_assoc.linked_in_outreaches.create!(sent_connection_request_at: Date.new)

    expect(campaign1.reload.prospects.to_a).to match_array([search1_prospect1])
    expect(campaign2.reload.prospects.to_a).to match_array([search1_prospect1])

    campaign1.campaign_search_associations.create!(search: search1)
    campaign2.campaign_search_associations.create!(search: search1)
    company.distribute_prospects_to_campaigns_idempotently
    campaign1.reload
    campaign2.reload

    expect(campaign1.reload.prospects.to_a).to match_array([search1_prospect1, search1_prospect2])
    expect(campaign2.reload.prospects.to_a).to match_array([search1_prospect1, search1_prospect3])
  end

  it "can assign a prospect, the prospect gets contacted, then run distribute again, prospect stays associated" do
    company = create(:user).company
    campaign1 = create(:campaign, company: company, name: "Campaign 1")
    search1 = create(:search, name: "Search 1", company: company)
    search1_prospect = search1.add_prospect!(linked_in_profile_url: "https://www.linkedin.com/sales/people/s1")
    campaign1.campaign_search_associations.create!(search: search1)

    company.distribute_prospects_to_campaigns_idempotently
    expect(campaign1.reload.prospects.to_a).to match_array([search1_prospect])

    assoc = search1_prospect.reload.prospect_campaign_associations.where(campaign: campaign1).first
    assoc.linked_in_outreaches.create!(sent_connection_request_at: Date.new)

    company.distribute_prospects_to_campaigns_idempotently
  end

  it "assigns no prospects to/removes prospects from campaigns if campaigns have no searches associated" do
    # in other words: the function works without failing if no prospects were assigned
    models = campaigns_with_assigned_unassigned_prospects

    models.company.distribute_prospects_to_campaigns_idempotently
    models.campaign1.reload
    models.campaign2.reload

    expect(models.campaign1.prospects.to_a).to match_array([])
    expect(models.campaign2.prospects.to_a).to match_array([])
  end

  it "assigns prospects to campaigns, when there are no duplicates" do
    models = campaigns_with_prospects_from_searches

    # removing cases where same search is assigned to multiple campaigns to test base case
    models.campaign1.campaign_search_associations.where(search: models.search3).first.destroy!
    models.campaign2.campaign_search_associations.where(search: models.search3).first.destroy!

    models.company.distribute_prospects_to_campaigns_idempotently

    # call twice to check idempotency
    models.company.distribute_prospects_to_campaigns_idempotently
    models.campaign1.reload
    models.campaign2.reload

    expect(models.campaign1.prospects.to_a).to match_array([models.search1_prospect])

    expect(models.campaign2.prospects.to_a).to match_array([models.search2_prospect])
  end

  it "assigns prospects to campaigns, splits duplicates between campaigns" do
    models = campaigns_with_prospects_from_searches
    expect(models.campaign1.prospects.to_a).to match_array([])

    models.company.distribute_prospects_to_campaigns_idempotently
    models.campaign1.reload
    models.campaign2.reload

    expect(models.campaign1.prospects.to_a).to match_array([models.search1_prospect, models.search3_porspect1])
    expect(models.campaign2.prospects.to_a).to match_array([models.search2_prospect, models.search3_porspect2])
  end

  it "reassigns prospects if a search is removed from a campaign" do
    models = campaigns_with_prospects_from_searches

    models.company.distribute_prospects_to_campaigns_idempotently

    models.campaign1.campaign_search_associations.where(search: models.search3).first.destroy!

    models.company.distribute_prospects_to_campaigns_idempotently
    models.campaign1.reload
    models.campaign2.reload

    expect(models.campaign1.prospects.to_a).to match_array([models.search1_prospect])
    expect(models.campaign2.prospects.to_a).to match_array([models.search2_prospect, models.search3_porspect1, models.search3_porspect2])
  end

  it "deletes prospects when their search is removed" do
    models = campaigns_with_prospects_from_searches
    models.company.distribute_prospects_to_campaigns_idempotently
    models.campaign1.reload
    expect(models.campaign1.prospects.to_a).to include(models.search1_prospect)

    models.campaign1.campaign_search_associations.where(search: models.search1).first.destroy!

    models.company.distribute_prospects_to_campaigns_idempotently
    models.campaign1.reload
    expect(models.campaign1.prospects.to_a).to_not include(models.search1_prospect)
  end

  it "doesn't delete prospects that have already been contacted" do
    models = campaigns_with_prospects_from_searches
    models.company.distribute_prospects_to_campaigns_idempotently
    models.campaign1.reload
    expect(models.campaign1.prospects.to_a).to include(models.search1_prospect)

    association = models.search1_prospect.prospect_campaign_associations.where(campaign: models.campaign1).first
    association.linked_in_outreaches.create!(sent_connection_request_at: Date.new)

    models.campaign1.campaign_search_associations.where(search: models.search1).first.destroy!

    models.company.distribute_prospects_to_campaigns_idempotently
    models.campaign1.reload

    expect(models.campaign1.prospects.to_a).to include(models.search1_prospect)
  end

  it "reassign prospects that have not already been contacted" do
    models = campaigns_with_prospects_from_searches
    models.company.distribute_prospects_to_campaigns_idempotently

    expect(models.campaign1.prospects.to_a).to match_array([models.search1_prospect, models.search3_porspect1])
    expect(models.campaign2.prospects.to_a).to match_array([models.search2_prospect, models.search3_porspect2])

    models.campaign2.campaign_search_associations.where(search: models.search3).first.destroy!

    models.company.distribute_prospects_to_campaigns_idempotently
    models.campaign1.reload
    models.campaign2.reload

    expect(models.campaign1.prospects.to_a).to match_array([models.search1_prospect, models.search3_porspect1, models.search3_porspect2])
    expect(models.campaign2.prospects.to_a).to match_array([models.search2_prospect])
  end

  it "doesn't reassign prospects that have already been contacted" do
    models = campaigns_with_prospects_from_searches
    models.company.distribute_prospects_to_campaigns_idempotently

    association = models.search3_porspect2.prospect_campaign_associations.where(campaign: models.campaign2).first
    association.linked_in_outreaches.create!(sent_connection_request_at: Date.new)

    models.campaign2.campaign_search_associations.where(search: models.search3).first.destroy!

    models.company.distribute_prospects_to_campaigns_idempotently
    models.campaign1.reload
    models.campaign2.reload

    expect(models.campaign1.prospects.to_a).to match_array([models.search1_prospect, models.search3_porspect1])
    expect(models.campaign2.prospects.to_a).to match_array([models.search2_prospect, models.search3_porspect2])
  end

  it "doesn't reassign prospects that have already been contacted even if the campaign that contacted the prospect is now paused" do
    models = campaigns_with_prospects_from_searches
    models.company.distribute_prospects_to_campaigns_idempotently

    association = models.search3_porspect2.prospect_campaign_associations.where(campaign: models.campaign2).first
    association.linked_in_outreaches.create!(sent_connection_request_at: Date.new)

    models.campaign2.campaign_search_associations.where(search: models.search3).first.destroy!
    models.campaign2.campaign_search_associations.where(search: models.search2).first.destroy!
    pp models.campaign2.reload.campaign_search_associations

    models.campaign2.update!(status: 2)

    pp "distribute"
    models.company.distribute_prospects_to_campaigns_idempotently
    models.campaign1.reload
    models.campaign2.reload

    expect(models.campaign1.prospects.to_a).to match_array([models.search1_prospect, models.search3_porspect1])
    expect(models.campaign2.prospects.to_a).to match_array([models.search3_porspect2])
  end

  it "assigns prospect p1 to campaigns in prospect pool p2 even if p1 has been used in another prospect pool" do
    company = create(:user, company: create(:company_with_prospect_pool)).company
    campaign1 = create(:campaign_belonging_to_prospect_pool, company: company, name: "Campaign 1")

    search1 = create(:search, name: "Search 1", company: company)
    search1_prospect1 = search1.add_prospect!(name: "Hugo S1P2 Boss", linked_in_profile_url: "https://www.linkedin.com/sales/people/s1", primary_company_name: "Almdudler")
    search1_prospect2 = search1.add_prospect!(name: "Karl S1P2 Wagner", linked_in_profile_url: "https://www.linkedin.com/sales/people/s2", primary_company_name: "Milka")

    campaign2 = create(:campaign_belonging_to_prospect_pool, company: company, name: "Campaign 2")

    _campaign1_search_1 = campaign1.campaign_search_associations.create!(search: search1)
    _campaign2_search_1 = campaign2.campaign_search_associations.create!(search: search1)

    # CAMPAIGN2 HAS ITS OWN PROSPECT POOL
    campaign2_pp = ProspectPool.create(company: company, name: "Campaign 2")
    campaign2.prospect_pool_campaign_associations.delete_all
    campaign2.prospect_pool_campaign_associations.create!(prospect_pool: campaign2_pp)

    company.distribute_prospects_to_campaigns_idempotently

    expect(campaign1.prospects.to_a).to match_array([search1_prospect1, search1_prospect2])
    expect(campaign2.prospects.to_a).to match_array([search1_prospect1, search1_prospect2])

    association = search1_prospect1.prospect_campaign_associations.where(campaign: campaign1).first
    association.linked_in_outreaches.create!(sent_connection_request_at: Date.new)

    company.distribute_prospects_to_campaigns_idempotently

    expect(campaign1.prospects.to_a).to match_array([search1_prospect1, search1_prospect2])
    expect(campaign2.prospects.to_a).to match_array([search1_prospect1, search1_prospect2])

    expect(campaign1.prospects.unused.to_a).to match_array([search1_prospect2])
    expect(campaign2.prospects.unused.to_a).to match_array([search1_prospect1, search1_prospect2])
  end


  it "prospects outside of prospect pool p1 are not influenced by a prospect pools de-dup" do
    company = create(:user, company: create(:company_with_prospect_pool)).company
    campaign1 = create(:campaign_belonging_to_prospect_pool, company: company, name: "Campaign 1")
    campaign1a = create(:campaign_belonging_to_prospect_pool, company: company, name: "Campaign 1a")

    search1 = create(:search, name: "Search 1", company: company)
    search1_prospect1 = search1.add_prospect!(name: "Hugo S1P2 Boss", linked_in_profile_url: "https://www.linkedin.com/sales/people/s1", primary_company_name: "Almdudler")
    search1_prospect2 = search1.add_prospect!(name: "Karl S1P2 Wagner", linked_in_profile_url: "https://www.linkedin.com/sales/people/s2", primary_company_name: "Milka")

    campaign2 = create(:campaign_belonging_to_prospect_pool, company: company, name: "Campaign 2")

    campaign1.campaign_search_associations.create!(search: search1)
    campaign1a.campaign_search_associations.create!(search: search1)
    campaign2.campaign_search_associations.create!(search: search1)

    # CAMPAIGN2 HAS ITS OWN PROSPECT POOL
    campaign2_pp = ProspectPool.create(company: company, name: "Campaign 2")
    campaign2.prospect_pool_campaign_associations.delete_all
    campaign2.prospect_pool_campaign_associations.create!(prospect_pool: campaign2_pp)

    company.distribute_prospects_to_campaigns_idempotently

    expect(campaign1.prospects.to_a).to match_array([search1_prospect1])
    expect(campaign1a.prospects.to_a).to match_array([search1_prospect2])
    expect(campaign2.prospects.to_a).to match_array([search1_prospect1, search1_prospect2])
  end

  it "splits equal prospects between campaigns even when they come through different searches" do
    company = create(:user, company: create(:company_with_prospect_pool)).company
    campaign1 = create(:campaign_belonging_to_prospect_pool, company: company, name: "Campaign 1")

    search1 = create(:search, name: "Search 1", company: company)
    search1_and2_prospect = search1.add_prospect!(linked_in_profile_url: "https://www.linkedin.com/sales/people/one_and_two")
    search1_prospect = search1.add_prospect!(linked_in_profile_url: "https://www.linkedin.com/sales/people/s1")

    campaign2 = create(:campaign_belonging_to_prospect_pool, company: company, name: "Campaign 2")
    search2 = create(:search, name: "Search 2", company: company)
    search1_and2_prospect.prospect_search_associations.create!(search: search2)
    search2_prospect = search2.add_prospect!(linked_in_profile_url: "https://www.linkedin.com/sales/people/s2")

    campaign1.campaign_search_associations.create!(search: search1)
    campaign2.campaign_search_associations.create!(search: search2)

    company.distribute_prospects_to_campaigns_idempotently
    campaign1.reload
    campaign2.reload

    expect(campaign2.prospects.to_a).to match_array([search2_prospect])
    expect(campaign1.prospects.to_a).to match_array([search1_and2_prospect, search1_prospect])
  end

  it "canl deal with the same prospect showing up in different searches for the same campaign" do
    company = create(:user, company: create(:company_with_prospect_pool)).company
    campaign1 = create(:campaign_belonging_to_prospect_pool, company: company, name: "Campaign 1")

    search1 = create(:search, name: "Search 1", company: company)
    search1_and2_prospect = search1.add_prospect!(linked_in_profile_url: "https://www.linkedin.com/sales/people/one_and_two")

    search2 = create(:search, name: "Search 2", company: company)
    search1_and2_prospect.prospect_search_associations.create!(search: search2)

    campaign1.campaign_search_associations.create!(search: search1)
    campaign1.campaign_search_associations.create!(search: search2)

    company.distribute_prospects_to_campaigns_idempotently
    campaign1.reload

    expect(campaign1.prospects.to_a).to match_array([search1_and2_prospect])
  end


  it "allows two campaigns to contact the same prospect if they're not part of the same prospect pool" do
    models = campaigns_with_prospects_from_searches

    models.campaign1.prospect_pool_campaign_associations.all.destroy_all
    prospect_pool2 = models.company.prospect_pools.create!(name: "New Prospect Pool")
    prospect_pool2.prospect_pool_campaign_associations.create!(campaign: models.campaign1)

    models.company.distribute_prospects_to_campaigns_idempotently


    expect(models.campaign1.reload.prospects.to_a).to match_array([models.search1_prospect, models.search3_porspect1, models.search3_porspect2])
    expect(models.campaign2.reload.prospects.to_a).to match_array([models.search2_prospect, models.search3_porspect1, models.search3_porspect2])

    prospect_campaign1_assoc = models.search3_porspect1.prospect_campaign_associations.where(campaign: models.campaign1).first
    prospect_campaign1_assoc.linked_in_outreaches.create!(sent_connection_request_at: Date.new)

    models.company.distribute_prospects_to_campaigns_idempotently

    expect(models.campaign1.reload.prospects.to_a).to match_array([models.search1_prospect, models.search3_porspect1, models.search3_porspect2])
    expect(models.campaign2.reload.prospects.to_a).to match_array([models.search2_prospect, models.search3_porspect1, models.search3_porspect2])

    models.campaign1_search_3.destroy
    models.company.distribute_prospects_to_campaigns_idempotently

    expect(models.campaign1.reload.prospects.to_a).to match_array([models.search1_prospect, models.search3_porspect1])
    expect(models.campaign2.reload.prospects.to_a).to match_array([models.search2_prospect, models.search3_porspect1, models.search3_porspect2])
  end

  it "it can deal with blacklists" do
    models = campaigns_with_prospects_from_searches
    models.company.distribute_prospects_to_campaigns_idempotently
    expect(models.campaign1.unused_prospects.not_blacklisted).to match_array([models.search1_prospect, models.search3_porspect1])
    expect(models.campaign2.unused_prospects.not_blacklisted).to match_array([models.search2_prospect, models.search3_porspect2])

    models.company.blacklisted_companies.create!(name: "Almdudler")
    item1 = models.company.blacklisted_companies.create!(name: "Cola")
    models.company.update!(last_blacklist_change: DateTime.now)
    models.company.distribute_prospects_to_campaigns_idempotently

    expect(models.campaign1.unused_prospects.not_blacklisted).to match_array([models.search3_porspect1])
    expect(models.campaign2.unused_prospects.not_blacklisted).to match_array([models.search2_prospect])
    expect(models.campaign1.unused_prospects.blacklisted).to match_array([models.search1_prospect, models.search3_porspect2])
    expect(models.campaign2.unused_prospects.blacklisted).to match_array([])

    item2 = models.company.blacklisted_companies.create!(name: "Microsoft")
    models.company.update!(last_blacklist_change: DateTime.now)
    models.company.distribute_prospects_to_campaigns_idempotently

    expect(models.campaign1.unused_prospects.not_blacklisted).to match_array([])
    expect(models.campaign2.unused_prospects.not_blacklisted).to match_array([models.search2_prospect])
    # this tests if blacklisted prospects get distributed evenly between campaigns
    expect(models.campaign1.unused_prospects.blacklisted).to match_array([models.search3_porspect1, models.search1_prospect])
    expect(models.campaign2.unused_prospects.blacklisted).to match_array([models.search3_porspect2])


    item1.destroy
    item2.destroy
    models.company.update!(last_blacklist_change: DateTime.now)
    models.company.distribute_prospects_to_campaigns_idempotently

    expect(models.campaign1.unused_prospects.not_blacklisted).to match_array([models.search3_porspect1])
    expect(models.campaign2.unused_prospects.not_blacklisted).to match_array([models.search2_prospect, models.search3_porspect2])

    models.company.blacklisted_people.create!(name: "Karl Wagner, BSc.")
    models.company.update!(last_blacklist_change: DateTime.now)
    models.company.distribute_prospects_to_campaigns_idempotently

    expect(models.campaign1.unused_prospects.not_blacklisted).to match_array([models.search3_porspect1])
    expect(models.campaign2.unused_prospects.not_blacklisted).to match_array([models.search3_porspect2])


    # adding a prospect that should be blacklisted later on still results in the prospect being blacklisted
    # checks if the chaching doesnt cache too eagerly
    models.company.blacklisted_companies.create!(name: "Newco")
    models.search3_prospect3 = models.search3.add_prospect!(linked_in_profile_url: "https://www.linkedin.com/sales/people/s3_3", primary_company_name: "Newco")


    models.company.distribute_prospects_to_campaigns_idempotently
    expect(models.campaign1.unused_prospects.not_blacklisted).to match_array([models.search3_porspect1])
    expect(models.campaign2.unused_prospects.not_blacklisted).to match_array([models.search3_porspect2])
  end

  it "can split two prospects being assigned to exactly two campaigns in a prospect pool with three campaigns" do
    models = campaigns_with_prospects_from_searches
    search3_prospect3 = models.search3.add_prospect!(linked_in_profile_url: "https://www.linkedin.com/sales/people/s3_3")

    campaign3 = create(:campaign_belonging_to_prospect_pool, company: models.company, name: "Campaign 3")

    models.company.distribute_prospects_to_campaigns_idempotently
    models.campaign1.reload
    models.campaign2.reload
    campaign3.reload

    expect(models.campaign1.prospects.pluck(:id) & models.campaign2.prospects.pluck(:id)).to match_array([])
    expect(models.campaign1.prospects.size + models.campaign2.prospects.size).to eq(5)
    expect(models.campaign1.prospects.to_a.map(&:linked_in_profile_url)).to match_array([models.search1_prospect, models.search3_porspect1, models.search3_porspect2].map(&:linked_in_profile_url))
    expect(models.campaign2.prospects.to_a.map(&:linked_in_profile_url)).to match_array([models.search2_prospect, search3_prospect3].map(&:linked_in_profile_url))
    expect(campaign3.prospects.to_a.map(&:linked_in_profile_url)).to match_array([])
  end


  def campaigns_with_assigned_unassigned_prospects
    company = create(:user).company
    campaign1 = create(:campaign, company: company)
    campaign2 = create(:campaign, company: company)

    assigned_twice = campaign1.add_prospect!(
      linked_in_profile_url: "https://www.linkedin.com/sales/people/twice",
    )

    assigned_once = campaign1.add_prospect!(
      linked_in_profile_url: "https://www.linkedin.com/sales/people/once",
    )

    assigned_twice.prospect_campaign_associations.create!(campaign: campaign2)

    unassigned = create(:campaign, company: company).add_prospect!(linked_in_profile_url: "https://www.linkedin.com/sales/people/unrelated")

    OpenStruct.new(company: company, campaign1: campaign1, campaign2: campaign2, assigned_twice: assigned_twice, assigned_once: assigned_once, unassigned: unassigned)
  end

  def campaigns_with_prospects_from_searches
    company = create(:user, company: create(:company_with_prospect_pool)).company
    campaign1 = create(:campaign_belonging_to_prospect_pool, company: company, name: "Campaign 1")

    search1 = create(:search, name: "Search 1", company: company)
    search1_prospect = search1.add_prospect!(name: "Hugo S1P Boss", linked_in_profile_url: "https://www.linkedin.com/sales/people/s1", primary_company_name: "Almdudler")

    campaign2 = create(:campaign_belonging_to_prospect_pool, company: company, name: "Campaign 2")
    search2 = create(:search, name: "Search 2", company: company)
    search2_prospect = search2.add_prospect!(name: "Karl S2P Wagner", linked_in_profile_url: "https://www.linkedin.com/sales/people/s2", primary_company_name: "Milka")

    search3 = create(:search, name: "Search 3", company: company)
    search3_porspect1 = search3.add_prospect!(name: "S3P1", linked_in_profile_url: "https://www.linkedin.com/sales/people/s3_1", primary_company_name: "Microsoft")
    search3_porspect2 = search3.add_prospect!(name: "S3P2", linked_in_profile_url: "https://www.linkedin.com/sales/people/s3_2", primary_company_name: "Cola")

    campaign1_search_1 = campaign1.campaign_search_associations.create!(search: search1)
    campaign1_search_3 = campaign1.campaign_search_associations.create!(search: search3)
    campaign2_search_2 = campaign2.campaign_search_associations.create!(search: search2)
    campaign2_search_3 = campaign2.campaign_search_associations.create!(search: search3)


    OpenStruct.new(company: company, campaign1: campaign1, campaign2: campaign2, search1: search1, search1_prospect: search1_prospect, search2: search2, search2_prospect: search2_prospect, search3: search3, search3_porspect1: search3_porspect1, search3_porspect2: search3_porspect2, campaign1_search_1: campaign1_search_1, campaign1_search_3: campaign1_search_3, campaign2_search_2: campaign2_search_2, campaign2_search_3: campaign2_search_3)
  end
end
