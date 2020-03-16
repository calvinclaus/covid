class LinkedInAccount < ApplicationRecord
  has_many :campaigns, dependent: :nullify
  has_many :logouts, dependent: :destroy
  before_save :maybe_set_logged_in
  validates_presence_of :name
  after_commit :notify_changed

  attr_accessor :frontend_id

  def notify_changed
    campaigns.each(&:on_linked_in_account_change)
  end

  def maybe_set_logged_in
    return if !li_at_changed? || !li_at.present?

    self.logged_in = true
  end

  def request_lock(any_model, argument)
    receive_lock = false
    transaction do
      reload
      any_model_gid = any_model.to_global_id.uri.to_s
      puts "request_lock called #{any_model_gid}, #{argument}"
      if lock_holder.present?
        puts "caller is put on waitlist"
        update_column(:lock_awaiters, lock_awaiters.concat([{gid: any_model_gid, argument: argument}]))
      else
        puts "caller will receive lock right away"
        update_column(:lock_holder, gid: any_model_gid, argument: argument)
        receive_lock = true
      end
    end
    any_model.linked_in_account_lock_received(self, argument) if receive_lock
  end

  def free_lock(any_model)
    transaction do
      reload
      any_model_gid = any_model.to_global_id.uri.to_s
      puts "Free lock called called #{any_model_gid}, current lock holder #{lock_holder}"
      raise "Cannot free lock. You are not the lock holder" if lock_holder.present? && any_model_gid != lock_holder["gid"]

      self.lock_holder = lock_awaiters.shift
      save!

      puts "new lock holder is #{lock_holder}"
    end

    puts "calling lock_received on new lock holder"
    GlobalID::Locator.locate(lock_holder["gid"]).linked_in_account_lock_received(self, lock_holder["argument"]) if lock_holder.present?
  end

  def browser
    return @browser if @browser.present?

    @browser = CapybaraHeadlessChrome.new_headless_browser
    @browser.visit("https://linkedin.com")
    pp "logging in with #{li_at}"
    @browser.driver.browser.manage.add_cookie(
      domain: '.www.linkedin.com',
      name: "li_at",
      value: li_at,
      path: '/',
      expires: (DateTime.now + 2.years)
    )
    @browser.visit("https://linkedin.com")
    if @browser.has_css?(".sign-in-form")
      handle_logged_out("Could not log in to LinkedIn")
    end
    self.logged_in = true
    save!

    @browser

    # puts @browser.driver.browser.manage.all_cookies
    # if self.cookie_jar.blank?
    # cookie = Mechanize::Cookie.new :domain => '.www.linkedin.com', :name => "li_at", :value => li_at, :path => '/', :expires => (Date.today + 2.years).to_s
    # browser.cookie_jar << cookie
    # else
    # @browser.cookie_jar.load(StringIO.new(self.cookie_jar))
    # end
    # @browser.user_agent_alias = USER_AGENT
  end

  def quit_browser!
    @browser.driver.quit if @browser.present?
  end

  def get(url)
    pp "visiting #{url} with linkedin account #{name}"
    browser.visit(url)


    if browser.current_url.include?("linkedin.com/authwall") || browser.has_css?(".upsell.module.card") # TODO add more logged out detection???
      handle_logged_out("Response to #{url} resulted in redirect to #{browser.current_url}. LinkedInAccount: id=#{id}, name=#{name}")
    end

    browser
  end

  def handle_logged_out(msg)
    self.logged_in = false
    save!
    LinkedInAccountMailer.logged_out_mail(self).deliver_now
    raise LoggedOutError, msg
  end

  class LoggedOutError < StandardError; end
end
