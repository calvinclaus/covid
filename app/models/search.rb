class Search < ApplicationRecord
  # add field last_synced_at for dirty calculation in statistic
  # or remove last synced at logic completely and a statistic is more of an immutable thing that gets deleted
  belongs_to :company
  has_many :prospect_search_associations, dependent: :delete_all
  has_many :prospects, through: :prospect_search_associations
  has_many :campaigns, through: :campaign_search_associations
  has_many :prospect_campaign_associations, through: :prospects # for statistic
  has_many :linked_in_outreaches, through: :prospect_campaign_associations # for statistic
  has_many :statistics, dependent: :delete_all
  belongs_to :linked_in_account, optional: true
  after_save :maybe_trigger_csv_sync, :maybe_trigger_clear_and_phantombuster_search
  has_one :linked_in_company_domain_finder
  accepts_nested_attributes_for :linked_in_company_domain_finder
  before_validation :prepare_csv_url
  validates_presence_of :search_result_csv_url, if: :uses_csv_import
  validate :csv_url_is_csv, if: :uses_csv_import
  validates_presence_of :linked_in_account, unless: :uses_csv_import

  scope :used_by_campaign, ->(campaign){
    joins(prospect_search_associations: {prospect: {prospect_campaign_associations: :linked_in_outreaches}}).where("prospect_campaign_associations.campaign_id = ?", campaign.id).distinct
  }

  include StatisticHelpers

  def prepare_statistics
    statistics.delete_all
    prepare_campaign_statistics
    prepare_weekly_statistics
    prepare_daily_statistics
    prepare_monthly_statistics
    prepare_full_statistic
    prepare_query_statistics
    touch
  end

  def linked_in_outreaches_for_statistics
    linked_in_outreaches.without_connection_error_or_sent_before_deadline_where_errors_count
  end

  def prepare_campaign_statistics
    Statistic.generate_block(
      self,
      linked_in_outreaches_for_statistics,
      group_by_sql: "prospect_campaign_associations.campaign_id",
      statistic_name_sql: "SELECT name from campaigns where id = num_delivered_table.grouped_by",
      kind: "campaign",
      data_sql: 'json_build_object(\'id\', num_delivered_table.grouped_by)',
    )
  end

  def prepare_query_statistics
    Statistic.generate_block(
      self,
      linked_in_outreaches_for_statistics.
        joins(prospect_campaign_association: {prospect: :prospect_search_associations}),
      group_by_sql: "prospect_search_associations.through_query",
      statistic_name_sql: "num_delivered_table.grouped_by",
      filter_query_sql: "num_delivered_table.grouped_by",
      kind: "query",
    )
  end


  attr_accessor :frontend_id

  def prepare_csv_url
    return if search_result_csv_url.blank?

    self.search_result_csv_url = search_result_csv_url.strip
    if search_result_csv_url.include?("google.com") && !search_result_csv_url.include?("?format=csv")
      self.search_result_csv_url = search_result_csv_url.split("/edit")[0].chomp("/") + "/export?format=csv"
    end
  end

  def csv_url_is_csv
    if search_result_csv_url.blank? || (!search_result_csv_url.include?(".csv") && !search_result_csv_url.include?("?format=csv"))
      errors.add(:search_result_csv_url, "Spreadsheet is not a Google Doc or CSV.")
    end
  end

  def maybe_trigger_csv_sync
    changes = saved_change_to_search_result_csv_url
    return unless changes.present?

    SearchResultSync.perform_later(self) if search_result_csv_url.present?
  end

  def maybe_trigger_clear_and_phantombuster_search
    changes = saved_change_to_linked_in_search_url
    return if !changes.present? && !should_redo?

    update_column(:should_redo, false)

    if should_clear?
      update_column(:should_clear, false)
      clear_associations
    end
    trigger_phantombuster_search
  end

  def clear_associations
    prospect_search_associations.delete_all
    compute_cache_columns
  end

  def add_prospect!(*args)
    prospect = company.prospects.create!(*args)
    prospect.prospect_search_associations.find_or_create_by!(search: self)
    prospect
  end

  def column_or_nil(header, row, column_name)
    return nil if header.find_index(column_name).blank?

    row[header.find_index(column_name)]
  end

  def compute_cache_columns
    update!(
      num_contacted_prospects: prospects.size - prospects.unused_or_unassigned.size,
      num_left_prospects: prospects.unused_or_unassigned.not_blacklisted.size,
      num_prospects: prospects.size,
      num_blacklisted_prospects: prospects.blacklisted.size,
      num_connection_errors: linked_in_outreaches.with_connection_error.size,
      num_connection_errors_after_deadline_where_errors_count: linked_in_outreaches.with_connection_error_sent_after_deadline_where_errors_count.size,
      queries: prospects.pluck(:through_query).uniq.map{ |q|
        {
          url: q,
          description: Campaign.sales_nav_search_query_description(q),
        }
      }
    )
  end

  def trigger_phantombuster_search
    return if !linked_in_search_url.present? || uses_csv_import?

    update!(running: true)

    prepared_execution = PhantombusterExecution.create!(
      agent_id: ENV['PHANTOMBUSTER_SEARCH_AGENT_ID'],
      argument: {
        "sessionCookie": linked_in_account.li_at,
        "searches": linked_in_search_url,
        "numberOfLinesPerLaunch": 1,
        "numberOfResultsPerSearch": linked_in_result_limit,
        "extractDefaultUrl": false,
        "removeDuplicateProfiles": false,
        "accountSearch": false,
      },
      argument_key_name_for_result_name: "csvName",
      callback_model_global_id: to_global_id.uri.to_s,
      callback_argument: linked_in_account.to_global_id.uri.to_s
    )
    update!(status: "WAITING FOR LINKED_IN_ACCOUNT")
    linked_in_account.request_lock(self, prepared_execution.to_global_id.uri.to_s)
  end

  def linked_in_account_lock_received(linked_in_account, prepared_execution_gid)
    puts "search received linked_in_accont_lock #{linked_in_account.name} #{prepared_execution_gid}"
    update!(status: "SEARCH EXECUTION STARTING")
    GlobalID::Locator.locate(prepared_execution_gid).execute
  end

  def phantombuster_execution_completed(execution, linked_in_account_gid)
    GlobalID::Locator.locate(linked_in_account_gid).free_lock(self)

    # TODO handle execution.error.present?
    if execution.error.present?
      return update!(running: false, status: execution.error)
    end

    if execution.console_output.include?("Error getting a response from LinkedIn, this may not be a Sales Navigator Account") || execution.console_output.include?("you don't have a Sales Navigator Account")
      return update!(running: false, status:  "LINKEDIN ACCOUNT IS NOT A SALES NAV ACCOUNT OR SALES NAV NOT ACTIVATED")
    end

    if execution.exit_code == 83
      return update!(running: false, status:  "LINKEDIN ACCOUNT LOGGED OUT")
    end

    if execution.exit_code != 0
      return update!(running: false, status:  "UNKNOWN ERROR")
    end


    update!(status: "SEARCH DONE - IMPORTING...")

    sync_prospects_from_csv(execution.result_csv)
  end

  def phantombuster_execution_progress(execution, _linked_in_account_gid)
    update!(status: "SEARCH EXECUTING (#{execution.progress['label']})")
  end

  def sync_prospects_from_csv_url
    update!(running: true)
    csv_response = Net::HTTP.get_response(URI(search_result_csv_url))
    csv = csv_response.body.force_encoding("UTF-8").encode("UTF-8")
    sync_prospects_from_csv(csv)
  end

  def sync_prospects_from_csv(csv)
    update!(status: "IMPORTING...")
    header, *rows = CSV.parse(csv, encoding: "UTF-8")

    if header.find_index("profileUrl").blank? && header.find_index("url").present?
      header[header.find_index("url")] = "profileUrl"
      header[header.find_index("currentJob")] = "title"
    end


    rows.each_with_index do |row, i|
      next unless row[header.find_index("profileUrl")].present?

      compute_cache_columns if ((i + 1) % 50) == 0

      transaction do
        profile_url = add_trailing_slash(row[header.find_index("profileUrl")])
        prospect = Prospect.find_or_create_by(linked_in_profile_url: profile_url, company: company)

        prospect.update!(
          name: column_or_nil(header, row, "name")&.strip,
          linked_in_profile_url: prospect.linked_in_profile_url.blank? ? profile_url : prospect.linked_in_profile_url,
          linked_in_profile_url_from_search: profile_url,
          vmid: Prospect.maybe_vmid(profile_url),
          title: column_or_nil(header, row, "title"),
          primary_company_name: column_or_nil(header, row, "companyName")&.strip,
          primary_company_linkedin_url: column_or_nil(header, row, "companyUrl"),
          location: column_or_nil(header, row, "location"),
          in_position_for: column_or_nil(header, row, "duration"),
        )


        prospect_search_association = prospect.prospect_search_associations.find_or_create_by!(search: self)

        prospect_search_association.update!(
          through_query: Search.remove_page_num_from_query(row[header.find_index("query")]),
          searched_at: column_or_nil(header, row, "timestamp").nil? ? DateTime.new : DateTime.parse(column_or_nil(header, row, "timestamp")),
        )
      end
    end
    update!(status: "DONE", running: false) # real update important to invalidate cache
    compute_cache_columns
    prepare_statistics
    Campaign.used_search(self).each(&:prepare_statistics)
    company.schedule_prospect_distribution
  end

  def self.remove_page_num_from_query(query)
    return "NONE" if query.blank?

    query = query.gsub(/(\?|&)page=\d+$/, "")
    query = query.gsub(/&page=\d+/, "")
    query.gsub(/page=\d+&/, "")
  end

  # TODO one location for this
  def add_trailing_slash(str)
    return str if str.last == "/"

    str + "/"
  end

  class SearchResultSync < ActiveJob::Base
    queue_as :immediate

    def perform(search)
      search.sync_prospects_from_csv_url
    end

    def error(_job, exception)
      ExceptionNotifier.notify_exception(exception)
    end
  end
end
