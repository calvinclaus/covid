require_relative '../../lib/company_name_equality/company_name_equality.rb'
require_relative '../../lib/human_name_utils/human_name_utils.rb'
class Company < ApplicationRecord
  has_many :users, ->{ order(created_at: :asc) }
  has_many :campaigns, ->{ order(created_at: :asc) }
  has_many :prospects
  has_many :prospect_campaign_associations, through: :prospects
  has_many :linked_in_outreaches, through: :prospect_campaign_associations
  has_many :blacklist_imports
  has_many :blacklisted_companies
  has_many :blacklisted_people
  has_many :searches, ->{ order(created_at: :asc) }
  has_many :credit_bookings, ->{ order(created_at: :asc) }
  belongs_to :reseller, optional: true, class_name: "Company"
  has_many :resold_companies, foreign_key: "reseller_id", class_name: "Company"
  has_many :prospect_pools, ->{ order(created_at: :asc) }
  validates_presence_of :name
  validates_associated :credit_bookings
  validates_associated :campaigns
  validates_associated :prospect_pools
  validates_associated :searches
  validates_associated :blacklist_imports

  accepts_nested_attributes_for :credit_bookings, allow_destroy: true
  accepts_nested_attributes_for :prospect_pools
  accepts_nested_attributes_for :campaigns
  accepts_nested_attributes_for :searches
  accepts_nested_attributes_for :blacklist_imports


  def self.send_credits_left_alert
    Company.all.each do |company|
      past = company.last_credits_left_alert_check_credit_amount
      now = company.total_credits - company.used_credits
      if past.present? && past > 250 && now <= 250
        CompanyMailer.credits_almost_empty_mail(company).deliver_now
      end
      company.update_attribute(:last_credits_left_alert_check_credit_amount, now)
    end
  end

  def compute_credits_left_cache
    update!(credits_left_cache: total_credits - used_credits, used_credits_cache: used_credits, total_credits_cache: total_credits)
  end

  def compute_cache_columns
    compute_credits_left_cache
    update!(
      num_prospects_without_search: prospects.without_search.size
    )
  end

  def total_credits
    credit_bookings.sum(:credit_amount)
  end

  def used_credits
    campaigns.all.inject(0) do |sum, campaign|
      sum + campaign.used_credits
    end
  end

  def campaigns_including_resold
    Campaign.where(company_id: [id, *resold_companies.pluck(:id)])
  end

  def compute_blacklist
    company_blacklist = blacklisted_companies.pluck(:name).map{ |n|
      {
        company_name: n,
        clean_company_name: CompanyNameEquality.clean_name(n),
      }
    }
    people_blacklist = blacklisted_people.pluck(:name)
    return if company_blacklist.empty? && people_blacklist.empty?

    prospects.where('last_blacklist_check <= ? OR last_blacklist_check IS NULL', last_blacklist_change).find_in_batches(batch_size: 250).each_with_index do |batch, i|
      GC.start if i != 0

      batch.each do |p|
        p.blacklisted = false
        p.blacklisted_reason = ""

        people_blacklist.each do |blacklist_item|
          if HumanNameUtils.fuzzy_equal?(p.name, blacklist_item)
            p.blacklisted = true
            p.blacklisted_reason += "#{blacklist_item} == #{p.name}\n"
          end
        end

        clean_company_name = CompanyNameEquality.clean_name(p.primary_company_name)
        company_blacklist.each do |blacklist_item|
          next unless CompanyNameEquality.same_company?(
            blacklist_item[:clean_company_name],
            clean_company_name,
            cleaned: true
          )

          p.blacklisted = true
          p.blacklisted_reason += "#{blacklist_item[:company_name]} == #{p.primary_company_name}\n"
        end

        p.last_blacklist_check = DateTime.now

        p.save!
      end
    end
  end

  def distribute_prospects_to_campaigns_idempotently
    reload

    unless searches.where(running: true).empty?
      update!(prospect_distribution_status: "WAITING FOR SEARCH(ES)")
      return Company::DistributeProspects.set(wait_until: Time.now + 10.seconds).perform_later(self)
    end

    update!(prospect_distribution_status: "RUNNING")
    begin
      update!(prospect_distribution_status: "RUNNING - COMPUTING BLACKLIST")
      compute_blacklist
      update!(prospect_distribution_status: "RUNNING - SYNCING PROSPECTS FROM SEARCHES")
      campaigns.each(&:sync_prospects_from_searches_keep_already_contacted)
      update!(prospect_distribution_status: "RUNNING - SPLITTING DUPLICATE ASSIGNMENTS")
      prospect_pools.each(&:split_dupliacte_assignments)
    rescue StandardError => e
      update!(prospect_distribution_status: "FAILED")
      ExceptionNotifier.notify_exception(e)
      pp e
      return
    end
    searches.each(&:compute_cache_columns)
    campaigns.each(&:mark_unknown_genders)
    campaigns.each(&:compute_cache_columns)
    compute_cache_columns
    update!(prospect_distribution_status: "DONE")
  end

  def schedule_prospect_distribution
    Delayed::Job.all.where('queue = ? and locked_at is null', 'immediate').map do |job|
      if GlobalID::Locator.locate(job.payload_object.job_data["arguments"].first["_aj_globalid"]) == self
        job.destroy
      end
    end
    update_column(:prospect_distribution_status, "WAITING")
    Company::DistributeProspects.perform_later(self)
  end

  class DistributeProspects < ActiveJob::Base
    queue_as :immediate

    def perform(company)
      company.distribute_prospects_to_campaigns_idempotently
    end

    def error(_job, exception)
      ExceptionNotifier.notify_exception(exception)
    end
  end
end
