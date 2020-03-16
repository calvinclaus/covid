class Prospect < ApplicationRecord
  has_many :prospect_campaign_associations, dependent: :delete_all
  has_many :campaigns, through: :prospect_campaign_associations
  has_many :prospect_search_associations, dependent: :delete_all
  has_many :searches, through: :prospect_search_associations
  has_many :linked_in_profile_scraper_results, dependent: :delete_all
  before_validation :add_trailing_slashes_to_urls
  validates :linked_in_profile_url, uniqueness: {scope: [:company_id]}
  scope :without_search, ->{
    where.not(
      ProspectSearchAssociation.
        where("prospects.id = prospect_search_associations.prospect_id").
        arel.exists
    ).distinct
  }
  scope :unused, ->{ joins(:prospect_campaign_associations).merge(ProspectCampaignAssociation.unused).distinct }
  scope :used, ->{ joins(:prospect_campaign_associations).merge(ProspectCampaignAssociation.used).distinct }
  scope :unused_or_unassigned, ->{ left_joins(:prospect_campaign_associations).merge(ProspectCampaignAssociation.unused).distinct }
  scope :assigned_to_multiple_campaigns_within_pool, ->(prospect_pool){
    where(
      ProspectCampaignAssociation.
        where("prospects.id = prospect_campaign_associations.prospect_id").
        joins(:prospect_pool_campaign_associations).
        where("prospect_pool_campaign_associations.prospect_pool_id": prospect_pool).
        assigned_to_multiple_campaigns.
        arel.exists
    )
  }
  scope :assigned_to_all, ->(campaigns){
    scope = Prospect.all
    campaigns.each do |campaign|
      scope = scope.where(
        ProspectCampaignAssociation.
        where("prospects.id = prospect_campaign_associations.prospect_id").
        where(campaign: campaign).
        arel.exists
      )
    end
    scope
  }

  scope :not_blacklisted, ->{ where(blacklisted: false) }
  scope :blacklisted, ->{ where(blacklisted: true) }
  scope :gender_not_unknown, ->{ where("gender_unknown = false OR gender_unknown IS NULL") }
  scope :gender_unknown, ->{ where("gender_unknown = true") }

  def linked_in_outreach(campaign)
    prospect_campaign_associations.where(campaign: campaign).first.linked_in_outreaches.first
  end

  def self.contains_vmid?(url)
    return true if url.include?("people/")
    return true if url.include?("in/AC")

    false
  end

  def self.maybe_vmid(url)
    return nil unless contains_vmid?(url)

    url = if url.split("sales").length > 1
            url.split("people/")[1]
          else
            url.split("in/")[1]
          end
    raise "VMID generation failed" unless url.present?

    url.split(",")[0]
  end

  def self.find_or_create_by(linked_in_profile_url: nil, company: nil)
    if contains_vmid?(linked_in_profile_url)
      vmid_find = company.prospects.where(vmid: maybe_vmid(linked_in_profile_url))
      if vmid_find.present?
        return vmid_find.first
      end
    end

    profile_url_find = company.prospects.where(
      linked_in_profile_url: add_trailing_slash(linked_in_profile_url)
    )
    return profile_url_find.first if profile_url_find.present?

    company.prospects.create!(
      linked_in_profile_url: add_trailing_slash(linked_in_profile_url),
      vmid: maybe_vmid(linked_in_profile_url)
    )
  end

  # TODO one location for this
  def self.add_trailing_slash(str)
    return str if str.last == "/"

    str + "/"
  end

  private

  # since we use urls to establish equality of prospects
  # we need to make sure we always safe with trailing slash
  def add_trailing_slashes_to_urls
    return if linked_in_profile_url.blank?
    return if linked_in_profile_url.last == "/"

    self.linked_in_profile_url = linked_in_profile_url + "/"
  end
end
