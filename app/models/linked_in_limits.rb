class LinkedInLimits
  MAX_INCREASE_OVER_DAYS = {
    "STANDARD": 30,
    "PREMIUM": 32,
    "SALES_NAVIGATOR": 40,
    "RECRUITER": 40,
  }.with_indifferent_access

  # the lower the faster the increase
  # min value 1.04 as decrease of 0.03 programmed after 1000 connections
  INCREASE_OVER_DAYS_LOG_BASE = {
    "STANDARD": 1.12,
    "PREMIUM": 1.12,
    "SALES_NAVIGATOR": 1.11,
    "RECRUITER": 1.11,
  }.with_indifferent_access


  PEOPLE_COUNT_TO_KEEP_MINIMUM = {
    "STANDARD": 200,
    "PREMIUM": 250,
    "SALES_NAVIGATOR": 500,
    "RECRUITER": 500,
  }.with_indifferent_access


  PEOPLE_COUNT_TO_KEEP_MULTIPLIER = {
    "STANDARD": 0.5,
    "PREMIUM": 0.5,
    "SALES_NAVIGATOR": 0.7,
    "RECRUITER": 0.7,
  }.with_indifferent_access


  MIN_DAILY_REQUESTS = {
    "STANDARD": 15,
    "PREMIUM": 17,
    "SALES_NAVIGATOR": 25,
    "RECRUITER": 25,
  }.with_indifferent_access

  MIN_REQUESTS_PENDING_DAYS = 7

  def self.save_daily_requests(account_type, num_connections, past_logouts, past_invocations)
    base_requests = (num_connections / 5).clamp(5, 20)

    active_days = smooth_operating_days(past_invocations, past_logouts)
    log_base = num_connections < 1000 ? INCREASE_OVER_DAYS_LOG_BASE[account_type] : INCREASE_OVER_DAYS_LOG_BASE[account_type] - 0.03
    increase_over_days = [(Math.log(1 + active_days, log_base) * 0.85 - 1).round, MAX_INCREASE_OVER_DAYS[account_type]].min


    calculated = base_requests + increase_over_days - decrease_through_logouts(past_logouts)
    calculated.clamp(MIN_DAILY_REQUESTS[account_type], (people_count_to_keep(account_type, num_connections, past_logouts, past_invocations) / MIN_REQUESTS_PENDING_DAYS).to_i)
  end

  def self.smooth_operating_days(innvocations, past_logouts, subtract_for_every_day_with_logout: 10)
    # -1 because the first invocation should still be the 0th day.
    operating_days = innvocations.map(&:to_date).uniq.size - 1
    # counting active days is halted by a logout occuring for subtract_for_every_day_with_logout days
    logout_recovery_days = (past_logouts.map(&:to_date) + [Date.today]).uniq.each_cons(2).reduce(0){ |sum, pair|
      sum + [(pair[1] - pair[0]).to_i, subtract_for_every_day_with_logout].min
    }

    [0, operating_days - logout_recovery_days].max
  end

  def self.decrease_through_logouts(past_logouts)
    past_logouts.reduce(0) do |sum, logout|
      reduction = (10 / (((DateTime.now.to_date - logout.to_date).to_i * 0.3) + 1)).round
      sum + reduction
    end
  end

  def self.logouts_in(past_logouts, last_days: 10)
    past_logouts.select{ |logout|
      (DateTime.now.to_date - logout.to_date) < last_days
    }.size
  end

  def self.people_count_to_keep(account_type, num_connections, past_logouts, past_invocations)
    min_multiplier = 1 + (smooth_operating_days(past_invocations, past_logouts) / 10) * 0.1 - logouts_in(past_logouts, last_days: 10) * 0.1
    min_multiplier = min_multiplier.clamp(1, 1.5)
    [1500, [num_connections * PEOPLE_COUNT_TO_KEEP_MULTIPLIER[account_type], PEOPLE_COUNT_TO_KEEP_MINIMUM[account_type] * min_multiplier].max].min.to_i
  end
end
