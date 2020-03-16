class CampaignSearchAssociation < ApplicationRecord
  belongs_to :campaign
  belongs_to :search

  attr_accessor :frontend_id
end
