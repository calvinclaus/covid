module StatisticHelpers
  delegate :num_delivered, :num_accepted, :num_not_accepted, :num_accepted_not_answered, :num_answered, :num_replied_after_stage, to: :full_statistic

  def full_statistic
    @loaded_full_statistic ||= statistics.where(kind: "full").first
    return Statistic.new if id.blank?

    if @loaded_full_statistic.blank?
      Statistic.generate_block(
        self,
        linked_in_outreaches_for_statistics,
        statistic_name_sql: "'Full'",
        period_type: "century",
        kind: "full",
      )
      @loaded_full_statistic = statistics.where(kind: "full").first
      # Statistic.generate_block unfortunately doesn't work if no outreaches have been made
      @loaded_full_statistic = Statistic.new if @loaded_full_statistic.blank?
    end
    @loaded_full_statistic
  end

  def weekly_statistics
    statistics.where(kind: "weekly").order(from: :desc)
  end

  def daily_statistics
    statistics.where(kind: "daily").order(from: :desc)
  end

  def monthly_statistics
    statistics.where(kind: "monthly").order(from: :desc)
  end

  def segmented_statistics
    statistics.where(kind: "segmented").order(from: :desc)
  end

  def query_statistics
    statistics.where(kind: "query").order(from: :desc).map{ |s|
      s.name = Campaign.sales_nav_search_query_description(s.name)
      s
    }
  end

  def campaign_statistics
    statistics.where(kind: "campaign").order(from: :desc)
  end

  def search_statistics
    statistics.where(kind: "search").order(from: :desc)
  end

  def prepare_full_statistic
    full_statistic
  end

  def prepare_weekly_statistics
    Statistic.generate_block(
      self,
      linked_in_outreaches_for_statistics,
      statistic_name_sql: Statistic.statistic_name_sql("week"),
      period_type: "week",
      kind: "weekly",
    )
  end

  def prepare_daily_statistics
    Statistic.generate_block(
      self,
      linked_in_outreaches_for_statistics,
      statistic_name_sql: Statistic.statistic_name_sql("day"),
      period_type: "day",
      kind: "daily",
    )
  end

  def prepare_monthly_statistics
    Statistic.generate_block(
      self,
      linked_in_outreaches_for_statistics,
      statistic_name_sql: Statistic.statistic_name_sql("month"),
      period_type: "month",
      kind: "monthly",
    )
  end

  def first_outreach_date
    return @first_outreach_date if @first_outreach_date.present?

    date = linked_in_outreaches_for_statistics.minimum(:sent_connection_request_at)
    date = date.present? ? date : DateTime.now
    @first_outreach_date = date
    @first_outreach_date
  end

  def last_outreach_date
    return @last_outreach_date if @last_outreach_date.present?

    date = linked_in_outreaches_for_statistics.maximum(:sent_connection_request_at)
    date = date.present? ? date : DateTime.now
    @last_outreach_date = date
    @last_outreach_date
  end

  def months_between(date1, date2)
    (date2.year * 12 + date2.month) - (date1.year * 12 + date1.month)
  end

  def weeks_between(date1, date2)
    date1.to_date.at_beginning_of_week.step(date2.to_date.at_end_of_week, 7).count
  end

  def days_between(date1, date2)
    (date2.to_date - date1.to_date).to_i
  end
end
