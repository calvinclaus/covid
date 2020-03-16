class BlacklistImport < ApplicationRecord
  belongs_to :company
  before_validation :prepare_csv_url
  has_many :blacklisted_companies
  has_many :blacklisted_people
  validates_presence_of :csv_url
  validate :csv_url_is_csv
  after_commit :maybe_trigger_blacklist_import
  attr_accessor :frontend_id


  def prepare_csv_url
    return if csv_url.blank?

    self.csv_url = csv_url.strip
    if csv_url.include?("google.com") && !csv_url.include?("?format=csv")
      self.csv_url = csv_url.split("/edit")[0].chomp("/") + "/export?format=csv"
    end
  end

  def csv_url_is_csv
    if csv_url.blank? || (!csv_url.include?(".csv") && !csv_url.include?("?format=csv"))
      errors.add(:csv_url, "Spreadsheet is not a Google Doc or CSV.")
    end
  end

  def maybe_trigger_blacklist_import
    changes = saved_change_to_csv_url
    return unless changes.present?

    BlacklistImportTask.perform_later(self) if csv_url.present?
  end

  def num_blacklisted
    raise "not implemented"
  end

  def column_names
    raise "not implemented"
  end

  def add_item?(_name)
    raise "not implemented"
  end

  def add_item(_name)
    raise "not implemented"
  end

  def start
    self.status = "IMPORTING"
    save!
    csv_response = Net::HTTP.get_response(URI(csv_url))
    header, *rows = CSV.parse(csv_response.body.force_encoding("UTF-8").encode("UTF-8"), encoding: "UTF-8")

    column_name = (header.map(&:downcase) & column_names.map(&:downcase)).first
    if column_name.present?
      name_index = header.map(&:downcase).find_index(column_name)
    else
      rows = [header] + rows
      name_index = 0
    end

    rows.each do |row|
      next if add_item?(row[name_index])

      add_item(row[name_index])
    end

    company.update!(last_blacklist_change: DateTime.now)


    self.status = "DONE"
    save!
  end

  class BlacklistImportTask < ActiveJob::Base
    queue_as :immediate

    def perform(blacklist_import)
      blacklist_import.start
    end

    def error(_job, exception)
      ExceptionNotifier.notify_exception(exception)
    end
  end
end
