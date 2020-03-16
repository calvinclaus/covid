class ProspectCampaignAssociation < ApplicationRecord
  belongs_to :prospect
  belongs_to :campaign
  has_many :prospect_pool_campaign_associations, through: :campaign
  has_many :linked_in_outreaches # using has_many as otherwise find_or_create_by doesn't work. on the db we have a uniqueness constraint though
  scope :unused, ->{ where.not(LinkedInOutreach.where("prospect_campaign_associations.id = linked_in_outreaches.prospect_campaign_association_id").arel.exists) }
  scope :used, ->{ where(LinkedInOutreach.where("prospect_campaign_associations.id = linked_in_outreaches.prospect_campaign_association_id").arel.exists) }
  scope :assigned_to_multiple_campaigns, ->{ select(:prospect_id).group(:prospect_id).having("count(prospect_id) > 1") }
end
