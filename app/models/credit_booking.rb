class CreditBooking < ApplicationRecord
  belongs_to :company
  validates_presence_of :name
  validates_presence_of :booking_date
  validates_presence_of :credit_amount
  validates_numericality_of :credit_amount

  attr_accessor :frontend_id

  after_commit :inform_company

  def inform_company
    company.compute_credits_left_cache
  end
end
