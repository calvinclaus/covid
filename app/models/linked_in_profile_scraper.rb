class LinkedInProfileScraper < ApplicationRecord
  has_one :campaign
  has_many :linked_in_profile_scraper_results, dependent: :delete_all

  validates :daily_scraping_target, numericality: {only_integer: true, greater_than: 0, less_than_or_equal_to: 60}, if: :active?

  after_commit :maybe_recompute_launch_times

  include LaunchTimeHelpers

  def self.tick
    current_tick_launch_time = LaunchTimeHelpers.current_launch_time
    LinkedInProfileScraper.where(active: true).each do |s|
      s.transaction do
        s.reload
        if LaunchTimeHelpers.launch_times_include(s.launch_times, current_tick_launch_time) &&
           s.last_tick_launch_time&.symbolize_keys != current_tick_launch_time
          s.update!(last_tick_launch_time: current_tick_launch_time)
          LinkedInProfileScraper::ScrapeJob.perform_later(s)
        end
      end
    end
  end

  def maybe_recompute_launch_times
    if saved_change_to_daily_scraping_target.present?
      recompute_launch_times
    end
  end

  def recompute_launch_times
    self.cached_launch_times = nil
    launch_times
  end

  def launch_times
    return cached_launch_times.with_indifferent_access if cached_launch_times.present?

    new_launch_times = {
      "timezone": campaign.timezone,
      "minute": [(Time.now.min - 5) % 60],
      "hour": distributed_nightly_launch_times,
      "day": (1..31).to_a,
      "dow": ["sun", "mon", "tue", "wed", "thu", "fri", "sat"],
      "month": ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"],
    }
    new_launch_times = pick_necessary_amount_of(new_launch_times, daily_scraping_target, additional_executions: 0)
    update_column("cached_launch_times", new_launch_times)
    new_launch_times.with_indifferent_access
  end

  def next_profiles_to_scrape
    campaign.prospects.
      left_outer_joins(:linked_in_profile_scraper_results).
      joins(prospect_campaign_associations: :linked_in_outreaches).
      where("linked_in_profile_scraper_results.id IS NULL").
      where("linked_in_outreaches.accepted_connection_request_at IS NOT NULL").
      where("prospect_campaign_associations_prospects.campaign_id = ?", campaign.id).
      order("linked_in_outreaches.sent_connection_request_at ASC").
      limit(10)
  end

  def linked_in_account
    campaign.linked_in_account
  end

  def scrape
    prepared_execution = PhantombusterExecution.create!(
      agent_id: ENV['PHANTOMBUSTER_LINKED_IN_PROFILE_SCRAPER_AGENT_ID'],
      argument: {
        "sessionCookie": linked_in_account.li_at,
        "spreadsheetUrl": Rails.application.routes.url_helpers.api_next_prospects_to_scrape_url(id: id, key: ENV['OUR_API_KEY']),
        "emailChooser": "none",
        "advancedSettings": true,
        "columnName": "profileUrl",
        "numberOfAddsPerLaunch": 10,
        "filterResults": false,
        "scrapeInterests": false,
        "saveImg": false,
        "takeScreenshot": false,
        "takePartialScreenshot": false,
        "onlyCurrentJson": false,
      },
      argument_key_name_for_result_name: "csvName",
      callback_model_global_id: to_global_id.uri.to_s,
      callback_argument: linked_in_account.to_global_id.uri.to_s
    )
    update!(status: "WAITING FOR LINKED_IN_ACCOUNT")
    linked_in_account.request_lock(self, prepared_execution.to_global_id.uri.to_s)
  end

  def linked_in_account_lock_received(linked_in_account, prepared_execution_gid)
    puts "linked in profile scraper received linked_in_accont_lock #{linked_in_account.name} #{prepared_execution_gid}"
    update!(status: "PROFILE SCRAPER STARTING")
    GlobalID::Locator.locate(prepared_execution_gid).execute
  end

  def phantombuster_execution_completed(execution, linked_in_account_gid)
    GlobalID::Locator.locate(linked_in_account_gid).free_lock(self)

    # TODO handle execution.error.present?
    if execution.error.present?
      return update!(status: execution.error)
    end

    if execution.exit_code == 83
      return update!(status:  "LINKEDIN ACCOUNT LOGGED OUT")
    end

    if execution.exit_code != 0
      return update!(status:  "UNKNOWN ERROR")
    end


    update!(status: "SCRAPING DONE - IMPORTING...")

    sync_scraping_results_from_csv(execution.result_csv)
  end

  def phantombuster_execution_progress(execution, _linked_in_account_gid)
    update!(status: "SCRAPER EXECUTING (#{execution.progress['label']})")
  end

  def sync_scraping_results_from_csv(csv)
    update!(status: "SYNCING RESULTS...")
    header, *rows = CSV.parse(csv, encoding: "UTF-8")

    rows.each_with_index do |row, _i|
      row_linked_in_url = column_or_nil(header, row, "baseUrl")
      next if row_linked_in_url.blank?
      prospect = campaign.prospects.where(linked_in_profile_url: Prospect.add_trailing_slash(row_linked_in_url)).first
      next if prospect.blank?

      transaction do
        scraper_result = prospect.linked_in_profile_scraper_results.find_or_create_by!(linked_in_profile_scraper: self)
        scraper_result.update!(
          email: column_or_nil(header, row, "mail"),
          phone: column_or_nil(header, row, "phoneNumber"),
          scraped_at: column_or_nil(header, row, "timestamp"),
          error: column_or_nil(header, row, "profileId") == "unavailable" ? "unavailable" : nil,
          raw_data: [header, row],
        )
      end
    end
    update!(status: "DONE")
  end

  def column_or_nil(header, row, column_name)
    return nil if header.find_index(column_name).blank?

    row[header.find_index(column_name)]
  end

  class ScrapeJob < ActiveJob::Base
    queue_as :fast_running

    def perform(scraper)
      scraper.scrape
    end

    def error(_job, exception)
      ExceptionNotifier.notify_exception(exception)
    end
  end
end
