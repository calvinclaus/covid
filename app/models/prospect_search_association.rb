class ProspectSearchAssociation < ApplicationRecord
  belongs_to :prospect
  belongs_to :search
end
