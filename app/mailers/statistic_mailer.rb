class StatisticMailer < ApplicationMailer
  def new_data_mail(user)
    @user = user
    mail(from: "COV19 <cov19@motion-group.at>", to: user.email, subject: "Neue COVID-19 Daten")
  end
end

