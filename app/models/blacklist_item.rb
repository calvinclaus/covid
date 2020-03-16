class BlacklistedCompany < ApplicationRecord
  belongs_to :company
  belongs_to :blacklist_import
end
