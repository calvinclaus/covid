class LinkedInOutreach < ApplicationRecord
  belongs_to :prospect_campaign_association

  DEADLINE_WHERE_ERRORS_COUNT = Time.parse("2020-02-10")

  scope :without_connection_error_or_sent_before_deadline_where_errors_count, ->{
    without_connection_error.or(where("sent_connection_request_at < ?", DEADLINE_WHERE_ERRORS_COUNT))
  }

  scope :with_connection_error_sent_after_deadline_where_errors_count, ->{
    with_connection_error.where("sent_connection_request_at >= ?", DEADLINE_WHERE_ERRORS_COUNT)
  }

  # because some errors turn out not to have been and because some errors in the
  # connection_request_error column are actually followup erorrs we check
  # if the request was accepted to reduce outreaches falsly marked as errors
  scope :without_connection_error, ->{
    where(%(
      connection_request_error IS NULL OR
      accepted_connection_request_at IS NOT NULL
    ))
  }

  scope :with_connection_error, ->{
    where(%(
      connection_request_error IS NOT NULL AND
      accepted_connection_request_at IS NULL
    ))
  }
end
