class CompanyMailer < ApplicationMailer
  def credits_almost_empty_mail(company)
    @company = company
    mail(from: "Motion CreditBot <creditbot@motion-group.at>", to: "ask@julianbauer.at,patrick.blaha@drei.at", subject: "#{@company.name} credits almost empty.")
  end
end
