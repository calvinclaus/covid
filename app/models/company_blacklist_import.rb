class CompanyBlacklistImport < BlacklistImport
  COMPANY_COLUMN_NAMES = [
    "companyname",
    "company",
    "firma",
    "firmenname",
  ].freeze

  def num_blacklisted
    blacklisted_companies.size
  end

  def column_names
    COMPANY_COLUMN_NAMES
  end

  def add_item?(name)
    company.blacklisted_companies.where(name: name).present?
  end

  def add_item(name)
    company.blacklisted_companies.create!(name: name, blacklist_import: self)
  end
end
