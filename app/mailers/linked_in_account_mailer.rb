class LinkedInAccountMailer < ApplicationMailer
  def logged_out_mail(linked_in_account)
    @linked_in_account = linked_in_account
    mail(from: "Motion LinkedInAccountBot <liabot@motion-group.at>", to: "calvinclaus@me.com", subject: "LinkedInAccount #{linked_in_account.name} was logged out :)")
  end
end
