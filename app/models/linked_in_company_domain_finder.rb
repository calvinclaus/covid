class LinkedInCompanyDomainFinder < ApplicationRecord
  belongs_to :search
  has_and_belongs_to_many :linked_in_accounts

  URLS_PER_ACCOUNT_PER_HOUR = 60
  COMPANY_LINK_SELECTOR = 'a[data-control-name="top_card_view_website_custom_cta_btn"], a[data-control-name="top_card_learn_more_custom_cta_btn"], a[data-control-name="top_card_view_contact_info_custom_cta_btn"], a[data-control-name="top_card_register_custom_cta_btn"], a[data-control-name="page_details_module_website_external_link"], a[data-control-name="top_card_sign_up_custom_cta_btn"]'.freeze

  def process_batch(urls)
    urls = urls.dup
    logged_in_linked_in_accounts.each do |linked_in_account|
      url = urls.pop
      next if url.blank?

      begin
        browser = linked_in_account.get(url)
        browser.current_url

        begin
          company_url = browser.find(COMPANY_LINK_SELECTOR, match: :first)[:href]
        rescue Capybara::ElementNotFound => e
          pp "rescuing ElementNotFound"
          pp e
          pp "Current browser url:"
          pp browser.current_url
          next
        end

        puts "company url is #{company_url}"
        search.prospects.where(primary_company_linkedin_url: url).each do |prospect|
          prospect.company_domains.push(add_trailing_slash(company_url))
          prospect.company_domains.uniq!
          prospect.processed_by_linked_in_company_domain_finder_at = DateTime.now
          prospect.save!
        end
      rescue LinkedInAccount::LoggedOutError => e
        puts "rescuing"
        pp e
        urls.push(url)
      end
    end
    puts "urls at end of batch #{urls}, present: #{urls.present?}"
    urls
  end

  def total
    search.prospects.where.not(primary_company_linkedin_url: [nil, ""]).size
  end

  def processed
    search.prospects.where.not(processed_by_linked_in_company_domain_finder_at: nil).size
  end

  def progress
    return 0 if total == 0

    100 * (processed / total)
  end

  def cached_linked_in_accounts
    return @cached_linked_in_accounts if @cached_linked_in_accounts.present?

    @cached_linked_in_accounts = linked_in_accounts
    @cached_linked_in_accounts
  end

  def logged_in_linked_in_accounts
    cached_linked_in_accounts.select do |acc|
      acc.reload.logged_in?
    end
  end

  def add_linked_in_company_urls_to_same_name_companies_without_url
    no_linked_in_url = search.prospects.
      where(primary_company_linkedin_url: [nil, ""]).
      where.not(primary_company_name: [nil, ""])
    no_linked_in_url.each do |prospect|
      matches = search.prospects.
        where.not(primary_company_linkedin_url: [nil, ""]).
        where(primary_company_name: prospect.primary_company_name).
        pluck(:primary_company_linkedin_url)
      matches = matches.concat(Prospect.
        where.not(primary_company_linkedin_url: [nil, ""]).
        where(primary_company_name: prospect.primary_company_name).
        pluck(:primary_company_linkedin_url))
      next unless matches.present?

      prospect.update!(primary_company_linkedin_url: matches.first)
    end
  end

  def work(skip_sleep: false)
    self.status = "RUNNING"
    save!

    add_linked_in_company_urls_to_same_name_companies_without_url
    GC.start

    company_urls = search.prospects.
      where("company_domains = '[]'").
      pluck(:primary_company_linkedin_url).uniq.select(&:present?)

    while company_urls.present?
      time_before = Time.now.to_i
      accounts = logged_in_linked_in_accounts
      raise AllAccountsLoggedOut if accounts.empty?

      next_urls = company_urls.pop(accounts.size)
      left_over = process_batch(next_urls)
      company_urls.push(*left_over)
      puts "done with process_batch"

      reload
      if status == "STOPPING" || status == "STOPPPED"
        break
      end

      GC.start
      to_sleep = ((60 * 60) / URLS_PER_ACCOUNT_PER_HOUR) - (Time.now.to_i - time_before)
      puts "Sleeping #{to_sleep} seconds"
      unless skip_sleep
        sleep(to_sleep)
      end
    end

    linked_in_accounts.each(&:quit_browser!)

    self.status = "STOPPED"
    save!
  end

  def add_trailing_slash(str)
    return str if str.last == "/"

    str + "/"
  end

  class FindDomains < ActiveJob::Base
    queue_as :long_running

    def perform(linked_in_company_domain_finder)
      linked_in_company_domain_finder.work
    end

    def error(_job, exception)
      ExceptionNotifier.notify_exception(exception)
    end
  end

  class AllAccountsLoggedOut < StandardError; end
end
