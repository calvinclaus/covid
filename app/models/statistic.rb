class Statistic < ApplicationRecord

  USER_AGENT = 'Opera/9.63 (Macintosh; Intel Mac OS X; U; en) Presto/2.1.1'.freeze
  def self.maybe_load_newest
    agent = request("https://www.sozialministerium.at/Informationen-zum-Coronavirus/Neuartiges-Coronavirus-(2019-nCov).html")
    text = agent.css("#content").first.text

    begin
      maybe_set_newest_from_table(agent)
    rescue Exception => e
      pp e
      ExceptionNotifier.notify_exception(e)
    end
  end

  def self.maybe_set_newest_from_table(agent)
    hash = { }
    agent.css("#content .table tbody tr").each do |elem|
      title = elem.css("th:first-child").first.text.downcase
      number = elem.css("td:last-child").first.text.gsub(".", "")
      if title.include?("test")
        hash[:num_tested] = number
        hash[:at] = DateTime.parse(title).asctime.in_time_zone("Europe/Vienna")
      end
      hash[:num_infected] = number and next if title.include?(" fälle") || title.include?("bestätigt")
      hash[:num_dead] = number and next if title.include?("tod") || title.include?("tot")
      hash[:num_recovered] = number and next if title.include?("genesen") || title.include?("gesund")
    end
    statistic = Statistic.where(at: hash[:at]).first
    if statistic.present?
      updated_at_before = statistic.updated_at
      statistic.update!(hash)
      updated_at_after = statistic.updated_at
      if updated_at_before != updated_at_after
        ExceptionNotifier.notify_exception(Exception.new("updated values"))
      end
    else
      statistic = Statistic.create!(hash)
      send_new_statistic_alerts
    end
  end

  def self.send_new_statistic_alerts
    pp "sending notification"
    ExceptionNotifier.notify_exception(Exception.new("new statistic added"))
    User.where(subscribed: true).each do |u|
      begin
        StatisticMailer.new_data_mail(u).deliver_now
      rescue Exception => e
        pp "failed to send, skipping, #{e}"
      end
    end
  end



  def self.request(url, raw = false)
    response = retry_if_nil do
      begin
        HTTParty.get(url, {
          headers: { 'User-Agent' => USER_AGENT }
        }).parsed_response
      rescue Exception => e
        puts "Exception #{e}"
        puts "returning nil"
        nil
      end
    end

    raw ? response : Nokogiri::HTML(response)
  end


  def self.retry_if_nil
    max_tries = 3
    tries = 0
    res = nil
    loop do
      res = yield
      tries += 1
      break if !res.nil? || tries > max_tries
      p "Sleeping 5 seconds in rety_if_nil"
      sleep(5)
    end
    res
  end
end
