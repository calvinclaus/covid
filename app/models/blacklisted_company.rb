class BlacklistedCompany < ApplicationRecord
  # it belongs to a company, i.e. on of our clients
  # but this model also contains a companyName referencing some other company to be blacklisted
  belongs_to :company
  belongs_to :blacklist_import, optional: true
end
