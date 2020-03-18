class StatisticMailerPreview < ActionMailer::Preview
  def new_data_mail
    User.where(email: "testemail@me.com").delete_all
    user = User.create!(email: "testemail@me.com")
    StatisticMailer.new_data_mail(user)
  end
end
