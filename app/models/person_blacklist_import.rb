class PersonBlacklistImport < BlacklistImport
  COLUMN_NAMES = [
    "name",
    "fullName",
  ].freeze

  def num_blacklisted
    blacklisted_people.size
  end

  def column_names
    COLUMN_NAMES
  end

  def add_item?(name)
    company.blacklisted_people.where(name: name).present?
  end

  def add_item(name)
    company.blacklisted_people.create!(name: name, blacklist_import: self)
  end
end
