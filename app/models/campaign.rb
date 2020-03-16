require 'uri'
require 'cgi'
require 'net/http'
require 'openssl'

class Campaign < ApplicationRecord
  belongs_to :company
  has_one :campaign_cache
  has_many :prospect_campaign_associations, dependent: :delete_all
  has_many :prospects, through: :prospect_campaign_associations
  has_many :prospect_search_associations, through: :prospects
  has_many :invocations, dependent: :delete_all
  validates_presence_of :name
  before_validation :convert_segment_dates, :maybe_recompute_launch_times
  after_save :export_config_to_phantombuster, :maybe_credits_left_changed, :maybe_status_changed, :maybe_segments_changed, :maybe_update_timezone_for_profile_scraper
  has_many :statistics, dependent: :delete_all
  has_many :campaign_search_associations
  has_many :searches, through: :campaign_search_associations
  belongs_to :linked_in_account
  belongs_to :linked_in_profile_scraper, optional: true
  has_many :prospect_pool_campaign_associations
  has_many :prospect_pools, through: :prospect_pool_campaign_associations

  validates_presence_of :message, if: :should_save_to_phantombuster?

  validates_presence_of :manual_daily_request_target, if: :manual_control?
  validates_presence_of :manual_people_count_to_keep, if: :manual_control?

  validate :validate_message_length, if: ->(record){ record.should_save_to_phantombuster? && record.llg? }

  validate :validate_follow_ups

  attr_readonly :script_type
  SCRIPT_TYPES = %w[LLG LM].freeze

  validates :script_type, inclusion: {in: SCRIPT_TYPES}

  scope :used_search, ->(search){
    joins(prospect_campaign_associations: [:linked_in_outreaches, prospect: :prospect_search_associations]).
      where("prospect_search_associations.search_id = ?", search.id).
      distinct
  }

  include StatisticHelpers
  include LaunchTimeHelpers

  # TODO prevent linkedinaccount change for a campaign that has already started

  def maybe_credits_left_changed
    if saved_change_to_follow_up_stages_to_count_as_credit_use.present?
      company.compute_credits_left_cache
    end
  end

  def maybe_status_changed
    if saved_change_to_status.present?
      update_column(:last_status_change_at, DateTime.current)
    end
  end

  def maybe_segments_changed
    if saved_change_to_segments.present?
      prepare_segmented_statistics
    end
  end

  def maybe_recompute_launch_times
    if timezone_changed?
      recompute_launch_times
    end
  end

  def maybe_update_timezone_for_profile_scraper
    if saved_change_to_timezone.present?
      linked_in_profile_scraper&.recompute_launch_times
    end
  end

  def self.redo_all_statistics
    companies = Company.all.order(id: :desc)
    size = companies.size
    companies.each_with_index do |c, i|
      puts "\n\n\n\n\n\n\n----------------------------#{c.name}: #{i}/#{size}------------------------\n\n\n\n\n\n\n"
      next if c.cleaned_up?

      transaction do
        c.compute_cache_columns
        c.searches.each(&:compute_cache_columns)
        c.searches.each(&:prepare_statistics)
        c.campaigns.each do |campaign|
          puts "\n\n\n\n\n\n\n----------------------------#{campaign.name}------------------------\n\n\n\n\n\n\n"
          campaign.compute_cache_columns
          campaign.prepare_statistics
        end
        c.update!(cleaned_up: true)
      end
    end
  end

  def self.cleanup_finished_agents
    # threadUrl -> profileUrl mapping is useful to prevent all threads being opened on restart
    # cleanest way would be to save that data with the linkedinaccount and whenever that linkedin account is
    # used make use of that data
    # reasonable way right now is to just save it and use it to init
    # saving the last database csv saves the work necessary to rebuild it
    # not-responded-cache save and use for init
    # init invocations with the invocations csv
    # program llg to prevent more than 10 followups to be sent for the immediate invocation
    # and teach it to go back to its last invocation in chat but max 14 days?
  end

  def total_contacted_and_contactable_prospects
    scope = prospects.not_blacklisted
    scope = scope.gender_not_unknown if MessageUtils.includes_gendered_salute?(message)
    scope
  end

  def compute_cache_columns
    update!(
      num_prospects: total_contacted_and_contactable_prospects.size,
      num_assigned_not_contacted_prospects: next_prospects.size,
      num_blacklisted: prospects.blacklisted.size,
      num_gender_unknown: MessageUtils.includes_gendered_salute?(message) ? prospects.not_blacklisted.gender_unknown.size : 0,
      num_not_contacted_and_blacklisted: unused_prospects.blacklisted.size,
      num_connection_errors: linked_in_outreaches.with_connection_error.size,
      num_connection_errors_after_deadline_where_errors_count: linked_in_outreaches.with_connection_error_sent_after_deadline_where_errors_count.size,
    )
  end

  def prepare_statistics
    statistics.delete_all
    reload
    prepare_full_statistic
    prepare_monthly_statistics
    prepare_weekly_statistics
    prepare_daily_statistics
    prepare_segmented_statistics
    prepare_query_statistics
    prepare_search_statistics
    touch
  end

  def llg?
    script_type == "LLG" || script_type.blank?
  end

  def lm?
    script_type == "LM"
  end

  def validate_message_length
    test_message = MessageUtils.populate_message(message, name: "Magdalena Musterfrau")
    if test_message.size > 300
      errors.add(:message, "is too long (maximum is 300 characters)")
    end
  end

  def validate_follow_ups
    follow_ups.each do |f|
      f["errors"] = {}
      if f["message"].blank?
        f["errors"]["message"] = ["Message can't be blank"]
        errors.add(:follow_ups, "Message can't be blank")
      end
      # todo add validation -> follow_up cant be set to immediate for message sender
    end
  end

  attr_accessor :frontend_id

  validates_associated :linked_in_account
  validates_associated :campaign_search_associations
  validates_associated :prospect_pool_campaign_associations
  validates_associated :linked_in_profile_scraper

  accepts_nested_attributes_for :linked_in_account
  accepts_nested_attributes_for :campaign_search_associations
  accepts_nested_attributes_for :prospect_pool_campaign_associations
  accepts_nested_attributes_for :linked_in_profile_scraper

  STATI = [
    {
      key: "1",
      description: "Running",
      number_of_adds_per_launch: 10,
      launch_type: "repeatedly",
    },
    {
      key: "2",
      description: "Paused with follow ups",
      number_of_adds_per_launch: 0,
      launch_type: "repeatedly",
    },
    {
      key: "3",
      description: "Paused fully",
      launch_type: "manually",
      number_of_adds_per_launch: 0,
    },
    {
      key: "4",
      description: "Finished - follow ups for 30 days",
      number_of_adds_per_launch: 0,
      launch_type: "repeatedly",
    },
    {
      key: "5",
      description: "Finished fully",
      number_of_adds_per_launch: 0,
      launch_type: "manually",
    },
  ].freeze

  def paused?
    status != "1"
  end

  def sync_invocations
    return if phantombuster_agent_id.blank?

    begin
      phantombuster_csv = phantombuster_invocations.body.force_encoding("UTF-8").encode("UTF-8")
      _, *rows = CSV.parse(phantombuster_csv, encoding: "UTF-8")
    rescue StandardError => e
      return ExceptionNotifier.notify_exception(e)
    end


    transaction do
      rows.each do |row|
        invocations.find_or_create_by(timestamp: DateTime.parse(row[0]))
      end
    end
  end

  def used_credits
    outreaches = linked_in_outreaches.without_connection_error_or_sent_before_deadline_where_errors_count.size
    followups = 0
    unless follow_up_stages_to_count_as_credit_use.empty?
      followups = LinkedInOutreach.from(%{
                            linked_in_outreaches INNER JOIN prospect_campaign_associations ON
                            linked_in_outreaches.prospect_campaign_association_id = prospect_campaign_associations.id,
                            jsonb_array_elements(linked_in_outreaches.follow_up_messages) as followup
                            }).
        where("followup->>'stage' IN (?)", follow_up_stages_to_count_as_credit_use).
        where('campaign_id = ?', id).count
    end
    outreaches + followups
  end

  def on_linked_in_account_change
    export_config_to_phantombuster
  end

  def export_config_to_phantombuster
    return unless should_save_to_phantombuster?


    result = phantombuster_save
    if result[:error].blank?
      update_column("phantombuster_errors", nil)
    else
      update_column("phantombuster_errors", result[:error])
    end
  end

  def convert_segment_dates
    self.segments = segments.select{ |s| s["date"].present? }
    self.segments = segments.map do |s|
      {name: s["name"], date: Date.parse(s["date"]).iso8601}
    end
    self.segments = segments.sort_by{ |s| s["date"] }.reverse
  end

  def sync_prospects_from_searches_keep_already_contacted
    # Remove prospects not in this list, but only if they weren't contacted yet
    unused_prospect_campaign_associations.delete_all

    # TODO test
    return if paused?

    # Add new prospects to campaign
    ProspectCampaignAssociation.import prospects_associated_through_searches_but_not_through_prospect_campaign_association.map{ |p|
      ProspectCampaignAssociation.new(prospect: p, campaign: self)
    }.to_a
  end

  def prospects_associated_through_searches_but_not_through_prospect_campaign_association
    prospects_associated_through_searches.where.not(prospect_campaign_associations.where('"prospects"."id" = "prospect_campaign_associations"."prospect_id"').arel.exists).distinct
  end

  def prospects_associated_through_searches
    Prospect.joins(:prospect_search_associations).merge(ProspectSearchAssociation.where(search: searches))
  end

  def unused_prospect_campaign_associations
    prospect_campaign_associations.unused
  end

  def unused_prospects
    Prospect.joins(:prospect_campaign_associations).merge(prospect_campaign_associations.unused)
  end

  def used_prospects
    Prospect.joins(:prospect_campaign_associations).merge(prospect_campaign_associations.used)
  end

  def add_prospect!(*args)
    prospect = company.prospects.create!(*args)
    prospect.prospect_campaign_associations.create!(campaign: self)
    prospect
  end

  def cache
    if campaign_cache.nil?
      CampaignCache.create!(campaign: self)
    else
      campaign_cache
    end
  end

  def adjust_daily_request_target
    logouts = linked_in_account.logouts.order('timestamp desc').limit(60).pluck(:timestamp).reverse
    plucked_invocations = Invocation.llg_invocations_of(linked_in_account).order('timestamp desc').limit(6 * 30 * 4).pluck(:timestamp).reverse
    new_daily_request_target = LinkedInLimits.save_daily_requests(
      linked_in_account.account_type,
      linked_in_account.num_connections,
      logouts,
      plucked_invocations,
    )
    new_people_count_to_keep = LinkedInLimits.people_count_to_keep(
      linked_in_account.account_type,
      linked_in_account.num_connections,
      logouts,
      plucked_invocations,
    )
    update!(
      automatic_people_count_to_keep: new_people_count_to_keep,
      automatic_daily_request_target: new_daily_request_target,
    )
    save_result = phantombuster_save
    unless save_result[:error].blank?
      ExceptionNotifier.notify_exception(Exception.new("Could not save adjusted daily_request_target to phantom. #{save_result}"))
    end
  end

  def sync_phantombuster
    return if phantombuster_agent_id.blank?

    begin
      phantombuster_csv = phantombuster_llg_result.body.force_encoding("UTF-8").encode("UTF-8")
      header, *rows = CSV.parse(phantombuster_csv, encoding: "UTF-8")
    rescue StandardError => e
      return ExceptionNotifier.notify_exception(e)
    end


    transaction do
      if cache.last_phantombuster_csv.present?
        _, *last_rows = CSV.parse(cache.last_phantombuster_csv, encoding: "UTF-8")

        rows = rows.select.with_index do |row, index|
          last_rows[index] != row
        end
      end

      rows.each do |row|
        next unless row[header.find_index("profileUrl")].present?

        has_base_url_col = header.find_index("baseUrl").present?
        vmid = some_vmid(has_base_url_col ? row[header.find_index("baseUrl")] : nil, row[header.find_index("profileUrl")])

        prospect_from_url = company.prospects.where(linked_in_profile_url: add_trailing_slash(row[header.find_index("profileUrl")])).first
        prospect = if prospect_from_url.present?
                     prospect_from_url
                   elsif vmid.present?
                     company.prospects.find_or_create_by(
                       vmid: vmid
                     )
                   else
                     company.prospects.create!(
                       linked_in_profile_url: add_trailing_slash(row[header.find_index("profileUrl")]),
                     )
                   end
        prospect.update!(
          linked_in_profile_url: add_trailing_slash(row[header.find_index("profileUrl")]),
          linked_in_profile_url_from_search: has_base_url_col ? row[header.find_index("baseUrl")] : row[header.find_index("profileUrl")],
          vmid: vmid,
          name: row[header.find_index("name")],
          email: header.find_index("email").present? ? row[header.find_index("email")] : nil,
        )
        association = prospect.prospect_campaign_associations.find_or_create_by!(campaign: self)


        if association.linked_in_outreaches.first.present? && !association.linked_in_outreaches.where(sent_connection_request_at: DateTime.parse(row[header.find_index("timestamp")])).present?
          # TODO ADD TEST FOR THIS CASE
          pp "This would create two outreaches for same person! Skipping second outreach"
          pp row
          next
        end
        # when syncing from phantombuster we don't have an ID on an outreach attempt
        # so we're using the timestamp to identify if we have already synched this outreach
        outreach = association.linked_in_outreaches.find_or_create_by(sent_connection_request_at: DateTime.parse(row[header.find_index("timestamp")]))
        outreach.update!(
          connection_message: row[header.find_index("message")],
          connection_request_error: header.find_index("error").present? ? row[header.find_index("error")] : nil,
          accepted_connection_request_at: header.find_index("acceptedRequestTimestamp").present? ? row[header.find_index("acceptedRequestTimestamp")] : nil,
          follow_up_messages: parse_follow_up_messages(header, row),
          replied_at: header.find_index("repliedAt").present? ? row[header.find_index("repliedAt")] : nil,
          follow_up_stage_at_time_of_reply: header.find_index("repliedDuringStage").present? ? row[header.find_index("repliedDuringStage")] : nil,
          thread_url: header.find_index("threadUrl").present? ? row[header.find_index("threadUrl")] : nil,
        )
      end

      Rails.logger.silence do
        campaign_cache.update!(last_phantombuster_csv: phantombuster_csv)
      end
      update!(last_synced_at: Time.current)
      prepare_statistics
    end
    transaction do
      company.searches.each(&:prepare_statistics)
    end
    compute_cache_columns
    company.compute_cache_columns
    company.searches.each(&:compute_cache_columns)
    prime_campaign_cache unless Rails.env.test?
    adjust_daily_request_target
  end

  def some_vmid(profile_url_1, profile_url_2)
    return Prospect.maybe_vmid(profile_url_1) if profile_url_1.present? && Prospect.contains_vmid?(profile_url_1)
    return Prospect.maybe_vmid(profile_url_2) if profile_url_2.present? && Prospect.contains_vmid?(profile_url_2)

    nil
  end

  def prime_campaign_cache
    url = URI(Rails.application.routes.url_helpers.api_prime_campaign_cache_url(id) + "?key=" + ENV['OUR_API_KEY'])
    http = Net::HTTP.new(url.host, url.port)
    if Rails.env.production?
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    request = Net::HTTP::Get.new(url)
    http.request(request)
    true
  end

  def add_trailing_slash(str)
    return str if str.last == "/"

    str + "/"
  end

  def parse_follow_up_messages(header, row)
    result = []
    stage = 1
    loop do
      ts_index = header.find_index("followUp#{stage}Timestamp")
      break unless ts_index.present? && row[ts_index].present?

      result.push(
        stage: stage,
        message: row[header.find_index("followUp#{stage}Message")],
        sent_timestamp: row[ts_index],
      )
      stage += 1
    end
    result
  end

  def recompute_launch_times
    self.phantombuster_launch_times = nil
    launch_times
  end

  def launch_times
    return phantombuster_launch_times if phantombuster_launch_times.present?

    generated_launch_times = {
      "timezone": timezone,
      "isSimplePresetEnabled": false,
      "minute": [(Time.now.min - 5) % 60],
      "hour": distributed_daily_launch_times,
      "day": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31],
      "dow": ["sun", "mon", "tue", "wed", "thu", "fri", "sat"],
      "month": ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"],
    }
    update_column("phantombuster_launch_times", generated_launch_times)
    phantombuster_launch_times
  end

  def status_data
    STATI.find{ |s| s[:key] == status }
  end

  def daily_request_target
    manual_control? ? manual_daily_request_target : automatic_daily_request_target
  end

  def people_count_to_keep
    manual_control? ? manual_people_count_to_keep : automatic_people_count_to_keep
  end

  def phantombuster_argument
    {
      "sessionCookie": linked_in_account.li_at,
      "spreadsheetUrl": Rails.application.routes.url_helpers.api_next_prospects_with_id_url(id: id, key: ENV['OUR_API_KEY']),
      "columnName": "profileUrl",
      "numberOfAddsPerLaunch": status_data[:number_of_adds_per_launch],
      "testMessageMode": false,
      "onlySecondCircle": false,
      "message": message,
      "followUps": follow_ups.map{ |f| {message: f["message"], daysDelay: f["days_delay"].to_i} },
      "disableScraping": true,
      "waitDuration": 15,
      "dailyRequestTarget": daily_request_target,
      "peopleCountToKeep": people_count_to_keep,
      "withdrawOnly": false,
      "profileLocale": profile_locale,
    }
  end

  def sync_phantombuster_agent_settings
    if should_save_to_phantombuster?
      puts "Not Syncing #{id}, #{name} as should_save_to_phantombuster=true"
      sleep(5)
      return
    end

    data = phantombuster_agent_data
    if data["error"] == "Agent not found"
      pp "agent not found"
      self.status = "5"
      save!
      return
    end
    pp data
    argument = JSON.parse(data["argument"])

    self.script_type = "LLG"
    self.script_type = "LM" if data["script"] == "MESSAGE_SENDER.js"

    if data["launchType"] == "manually"
      self.status = "3" if status != "5"
    elsif argument["numberOfAddsPerLaunch"] == 0
      self.status = "2" if status != "4"
    else
      self.status = "1"
    end

    linked_in_account.update_column(:li_at, argument["sessionCookie"])

    self.message = argument["message"]

    self.follow_ups = argument["followUps"].map{ |f| {message: f["message"], days_delay: f["daysDelay"].to_i} }

    self.manual_daily_request_target = argument["dailyRequestTarget"]
    self.manual_people_count_to_keep = argument["peopleCountToKeep"]

    pp id
    pp name
    pp script_type
    pp status
    pp message
    pp follow_ups
    pp manual_daily_request_target
    pp manual_people_count_to_keep

    save!
  end

  def phantombuster_save
    return {error: ""} unless should_save_to_phantombuster?

    uri = URI("https://api.phantombuster.com/api/v2/agents/save")
    header = {'Content-Type': 'application/json', 'X-Phantombuster-Key': ENV['PHANTOMBUSTER_API_KEY']}

    body = {
      "org": "user-org-26621",
      "script": lm? ? "MESSAGE_SENDER.js" : "LLG_DEV.js",
      "branch": "master",
      "environment": "staging",
      "name": name + " (D)",
      "id": phantombuster_agent_id.blank? ? "" : phantombuster_agent_id, # if blank new agent created
      "argument": JSON.pretty_generate(phantombuster_argument),
      "notifications": {
        mailAutomaticExitError: true,
        mailAutomaticExitSuccess: false,
        mailAutomaticLaunchError: true,
        mailAutomaticTimeError: true,
        mailManualExitError: false,
        mailManualExitSuccess: false,
        mailManualLaunchError: false,
        mailManualTimeError: false,
      },
      "executionTimeLimit": 1200000, # this doesnt get set on creation for some reason. i decided against correcting for this by sending two api requests to pb. so execution time limit does not get set at the moment.
      "launchType": status_data[:launch_type],
      "repeatedLaunchTimes": pick_necessary_amount_of(launch_times, daily_request_target, additional_executions: 1),
    }

    return {error: ""} if !phantombuster_errors.present? && cache.last_saved_phantombuster_config == body.deep_stringify_keys

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Post.new(uri.request_uri, header)
    request.body = body.to_json

    response = http.request(request)
    result = JSON.parse(response.body)
    Rails.logger.info "Phantombuster save result #{result}"

    # the creation does not include an id - but we still want to creation to be cached so we pretend we already knew it when caching our last request
    body["id"] = result["id"].to_s if body["id"].blank?
    cache.update!(last_saved_phantombuster_config: body)

    if result["status"] == "error" && result["error"].include?("Your current plan allows for a maximum of")
      # check what to do - maybe set error on the object, probably responsibility of the caller...?
      # deal with no more slots
      return {error: "No more campaign slots available. Contact calvin@motion-group.com."}
    elsif result["status"] == "error" && result["error"] == "Agent not found"
      update_column(:phantombuster_agent_id, nil)
      return phantombuster_save
    end
    return {error: result["error"]} if result["status"] == "error"

    update_column(:phantombuster_agent_id, result["id"])

    {error: ""}
  end

  def phantombuster_invocations
    retry_if_nil do
      url = URI("https://phantombuster.com/api/v1/agent/#{phantombuster_agent_id}")

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Get.new(url)
      request["accept"] = 'application/json'
      request["X-Phantombuster-Key-1"] = ENV['PHANTOMBUSTER_API_KEY']

      response = http.request(request)
      result = JSON.parse(response.body)

      Rails.logger.info "Phantombuster call result #{result}"

      next OpenStruct.new(body: "") if result["error"] == "Agent not found"
      next nil if result["status"] != "success"

      result = result["data"]

      result_csv_url = "https://phantombuster.s3.amazonaws.com/#{result['userAwsFolder']}/#{result['awsFolder']}/invocations.csv"
      resp = Net::HTTP.get_response(URI(result_csv_url))

      resp
    end
  end

  def phantombuster_agent_data
    url = URI("https://api.phantombuster.com/api/v2/agents/fetch?id=#{phantombuster_agent_id}&withManifest=true")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(url)
    request["accept"] = 'application/json'
    request["X-Phantombuster-Key"] = ENV['PHANTOMBUSTER_API_KEY']

    response = http.request(request)
    result = JSON.parse(response.body)

    result
  end

  def phantombuster_llg_result
    retry_if_nil do
      url = URI("https://phantombuster.com/api/v1/agent/#{phantombuster_agent_id}")

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Get.new(url)
      request["accept"] = 'application/json'
      request["X-Phantombuster-Key-1"] = ENV['PHANTOMBUSTER_API_KEY']

      response = http.request(request)
      result = JSON.parse(response.body)

      Rails.logger.info "Phantombuster call result #{result}"

      next OpenStruct.new(body: "") if result["error"] == "Agent not found"
      next nil if result["status"] != "success"

      result = result["data"]

      result_csv_url = "https://phantombuster.s3.amazonaws.com/#{result['userAwsFolder']}/#{result['awsFolder']}/database-linkedin-network-booster.csv"
      resp = Net::HTTP.get_response(URI(result_csv_url))

      if resp.code == "403"
        result_csv_url = "https://phantombuster.s3.amazonaws.com/#{result['userAwsFolder']}/#{result['awsFolder']}/linkedin-chat-send-message.csv"
        resp = Net::HTTP.get_response(URI(result_csv_url))
      end
      resp
    end
  end

  def retry_if_nil
    max_tries = 3
    tries = 0
    res = nil
    loop do
      res = yield
      tries += 1
      break if !res.nil? || tries > max_tries

      pp "Sleeping in rety_if_nil"
      sleep(30)
    end
    res
  end

  def prepare_segmented_statistics
    statistics.where(kind: "segmented").delete_all

    segs = segments.reverse
    prev_segment = {"name": "Start", "date": nil}.stringify_keys
    segs.push({})
    segs.each_with_index do |curr_segment, _index|
      from = prev_segment["date"].blank? ? first_outreach_date : DateTime.parse(prev_segment["date"])
      to = curr_segment["date"].blank? ? last_outreach_date : (DateTime.parse(curr_segment["date"]) - 1.days).end_of_day
      Statistic.generate_block(
        self,
        linked_in_outreaches_for_statistics.where('sent_connection_request_at >= ? AND sent_connection_request_at <= ?', from, to),
        period_type: "century",
        statistic_name_sql: "'#{prev_segment['name']}'",
        kind: "segmented",
      )
      prev_segment = curr_segment
    end
  end

  def prepare_search_statistics
    Statistic.generate_block(
      self,
      linked_in_outreaches_for_statistics.
        joins(prospect_campaign_association: {prospect: :prospect_search_associations}),
      group_by_sql: "prospect_search_associations.search_id",
      statistic_name_sql: "SELECT name from searches where id = num_delivered_table.grouped_by",
      kind: "search",
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

  def self.mark_unknown_genders_for_next_prospects_in_all_campaigns
    Campaign.where(status: 1).each(&:mark_unknown_genders)
  end

  def mark_unknown_genders
    return unless MessageUtils.includes_gendered_salute?(message)

    next_prospects(limit: 30).select{ |p| p.gender_unknown.nil? }.each do |p|
      begin
        HumanNameUtils.gender(
          first_name: HumanNameUtils.clean_and_split_name(p.name).first,
        )
        p.update!(gender_unknown: false)
      rescue GenderNotFound => _e
        p.update!(gender_unknown: true)
      end
    end
    compute_cache_columns
  end

  def next_prospects(limit: nil)
    scope = unused_prospects.
      not_blacklisted.
      select("prospects.*, MIN(campaign_search_associations.id) as search_association_id").
      joins(:campaigns).
      left_joins(:prospect_search_associations).
      joins("LEFT OUTER JOIN campaign_search_associations ON campaign_search_associations.campaign_id = campaigns.id").
      where('campaign_search_associations.search_id = prospect_search_associations.search_id OR prospect_search_associations.search_id IS NULL').
      includes(:prospect_search_associations).
      order("search_association_id", "prospects.id").
      group("prospects.id").
      limit(limit)

    scope = scope.gender_not_unknown if MessageUtils.includes_gendered_salute?(message)

    # to make .size work we need to wrap the query above that uses group by in another query
    scope = Prospect.from(scope, :prospects)

    scope
  end

  def self.sales_nav_search_query_description(query)
    return "EMPTY" if query.blank?

    hash = CGI.parse(query.split('?').last)
    str = ""
    str += translate_keywords(hash["keywords"]&.first) + "\n"
    str += translate_region(hash["geoIncluded"]&.first&.split(",")) + "\n"
    str += translate_company_size(hash["companySize"]&.first&.split(",")) + "\n"
    str += translate_years_of_experience(hash["yearsOfExperience"]&.first&.split(",")) + "\n"
    str += translate_tenure_at_current_company(hash["tenureAtCurrentCompany"]&.first&.split(",")) + "\n"
    str += translate_seniority(hash["seniorityIncluded"]&.first&.split(",")) + "\n"
    str += translate_spotlight(hash["spotlight"]&.first) + "\n"
    str += translate_relationship(hash["relationship"]&.first&.split(","))
    str = str.gsub(/(\n)+/, "\n")
    str = str.gsub(/\n$/, "")
    return "UNKNOWN" if str.blank?

    str
  end

  def self.translate_keywords(words)
    return "" if words.blank?

    "Keywords: #{words}"
  end

  def self.translate_relationship(array)
    return "" if array.blank?

    str = "Rel: "
    rels = {
      "F": "1st",
      "S": "2nd",
      "A": "Group",
      "O": "3rd+",
    }.with_indifferent_access
    str + array.map{ |id|
      rels[id]
    }.join("; ")
  end

  def self.translate_spotlight(key)
    return "" if key.blank?
    if key == "RECENTLY_POSTED_ON_LINKEDIN"
      return "Active"
    elsif key == "RECENT_POSITION_CHANGE"
      return "Recent job change"
    elsif key == "COMMONALITIES"
      return "Has commonalities"
    end

    ""
  end

  def self.translate_seniority(array)
    return "" if array.blank?

    str = "Seniority: "
    seniorities = {
      "1": "Unbezahlt",
      "2": "Praktikant",
      "3": "Einsteiger",
      "4": "Erfahren",
      "5": "Manager",
      "6": "Director",
      "7": "VP",
      "8": "CEO",
      "9": "Partner",
      "10": "Owner",
    }.with_indifferent_access
    str + array.map{ |id|
      seniorities[id]
    }.join("; ")
  end

  def self.translate_region(array)
    return "" if array.blank?

    regions = {
      "103883259": "AT",
      "101282230": "DE",
      "101165590": "UK",
      "106693272": "CH",
      "90009888": "Zürich Area",
      "102436504": "Zürich",
      "90009886": "Geneva Area",
      "104406358": "Geneva",
      "103644278": "USA",
      "90009882": "Wien",
      "104669944": "Wien",
      "107144641": "Wien",
    }.with_indifferent_access
    array.map{ |id|
      regions[id].present? ? regions[id] : id
    }.join("; ")
  end

  def self.translate_tenure_at_current_company(array)
    return "" if array.blank?

    str = "Years in co.: "
    years = {
      "1": "< 1",
      "2": "1-2",
      "3": "3-5",
      "4": "6-10",
      "5": "> 10",
    }.with_indifferent_access
    str + array.map{ |id|
      years[id]
    }.join("; ")
  end

  def self.translate_years_of_experience(array)
    return "" if array.blank?

    str = "Years exp: "
    years = {
      "1": "< 1",
      "2": "1-2",
      "3": "3-5",
      "4": "6-10",
      "5": "> 10",
    }.with_indifferent_access
    str + array.map{ |id|
      years[id]
    }.join("; ")
  end

  def self.translate_company_size(array)
    return "" if array.blank?

    sizes = {
      "A": "Solo",
      "B": "1-10",
      "C": '11-50',
      "D": '51-200',
      "E": '201-500',
      "F": '501-1000',
      "G": '1001-5000',
      "H": '5001-10.000',
      "I": '10.000+',
    }.with_indifferent_access
    array.map{ |size|
      sizes[size]
    }.join("; ")
  end

  def linked_in_outreaches_for_statistics
    linked_in_outreaches.without_connection_error_or_sent_before_deadline_where_errors_count
  end

  def linked_in_outreaches
    LinkedInOutreach.joins(:prospect_campaign_association).
      where('prospect_campaign_associations.campaign_id=?', id)
  end

  def linked_in_account_name
    return "NONE" unless linked_in_account.present?

    linked_in_account.name
  end

  class PhantombusterSync < ActiveJob::Base
    queue_as :fast_running

    def perform(campaign)
      campaign.sync_phantombuster
    end

    def error(_job, exception)
      ExceptionNotifier.notify_exception(exception)
    end
  end
end
