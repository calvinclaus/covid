class BlacklistedPerson < ApplicationRecord
  belongs_to :company
  belongs_to :blacklist_import, optional: true
end
