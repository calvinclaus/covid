class Statistic < ApplicationRecord

  USER_AGENT = 'Opera/9.63 (Macintosh; Intel Mac OS X; U; en) Presto/2.1.1'.freeze
  def self.maybe_load_newest
    agent = request("https://www.sozialministerium.at/Informationen-zum-Coronavirus/Neuartiges-Coronavirus-(2019-nCov).html")
    text = agent.css(".abstract").first.text

    begin
      maybe_set_newest_from_text(text)
    rescue Exception => e
      pp e
      ExceptionNotifier.notify_exception(e)
    end
  end

  def self.maybe_set_newest_from_text(text)
    hash = { }

    text.split("\n").each do |line|
      if line.downcase.include?("uhr") || line.downcase.include?("stand")
        hash[:at] = DateTime.parse(line).asctime.in_time_zone("Europe/Vienna")
      end

      number_line = line.gsub(".", "").downcase
      if number_line.include? "test"
        hash[:num_tested] = number_line.scan(/\d+/).first
      end
      if number_line.include?(" fälle") || number_line.include?("bestätigt")
        hash[:num_infected] = number_line.scan(/\d+/).first
      end
      if number_line.include?("genesen") || number_line.include?("gesund")
        hash[:num_recovered] = number_line.scan(/\d+/).first
      end
      if number_line.include?("tod") || number_line.include?("tot")
        hash[:num_dead] = number_line.scan(/\d+/).first
      end
    end

    statistic = Statistic.where(at: hash[:at]).first
    if statistic.present?
      updated_at_before = statistic.updated_at
      statistic.update!(hash)
      updated_at_after = statistic.updated_at
      if updated_at_before != updated_at_after
        pp "sending notification"
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
      StatisticMailer.new_data_mail(u).deliver_now
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
