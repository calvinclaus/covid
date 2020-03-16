class ProspectPoolCampaignAssociation < ApplicationRecord
  belongs_to :campaign
  belongs_to :prospect_pool
  has_many :prospect_campaign_associations, through: :campaign

  attr_accessor :frontend_id
end
