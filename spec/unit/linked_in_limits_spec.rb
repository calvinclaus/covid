require 'rails_helper'

RSpec.describe "LinkedInLimits" do
  # rubocop:disable Metrics/ParameterLists:
  def send_and_keep(account_type, num_connections, past_logouts, past_invocations, day: 1, total_sent: 0)
    send = LinkedInLimits.save_daily_requests(account_type, num_connections, past_logouts, past_invocations)
    keep = LinkedInLimits.people_count_to_keep(account_type, num_connections, past_logouts, past_invocations)
    puts "#{day}: #{account_type}, connections: #{num_connections}, #{past_logouts.size} logouts, #{past_invocations.size} invocs | send: #{send}, keep: #{keep}, total_sent #{total_sent}"
    send
  end
  # rubocop:enable Metrics/ParameterLists:

  def invoc_days(count, per_day: 1)
    res = []
    (0...count).each do |i|
      (0...per_day).each do |j|
        res.push(Time.at(Time.current.to_i + i * 60 * 60 * 24 + 60 * 60 * j))
      end
    end
    res
  end

  def simulate(account_type, initial_connections, connection_rate, days)
    puts "SIMULATING. #{account_type}, #{initial_connections} connections, #{connection_rate} rate, #{days} days"
    last_sent = 0
    total_sent = 0
    current_connections = initial_connections
    send_and_keep(account_type, current_connections, [], invoc_days(0), day: 0)
    (1..days).each do |d|
      current_connections = (current_connections + last_sent * connection_rate).round
      last_sent = send_and_keep(account_type, current_connections, [], invoc_days(d), day: d, total_sent: total_sent)
      total_sent += last_sent
    end
  end

  # it "initiates reasonably" do
  #   send_and_keep("STANDARD", 0, [], [])
  #   send_and_keep("STANDARD", 10, [], [])
  #   send_and_keep("STANDARD", 50, [], [])
  #   send_and_keep("STANDARD", 250, [], [])
  #   send_and_keep("STANDARD", 500, [], [])
  #   send_and_keep("STANDARD", 1000, [], [])
  #   send_and_keep("STANDARD", 4000, [], [])

  #   send_and_keep("PREMIUM", 0, [], [])
  #   send_and_keep("PREMIUM", 10, [], [])
  #   send_and_keep("PREMIUM", 50, [], [])
  #   send_and_keep("PREMIUM", 250, [], [])
  #   send_and_keep("PREMIUM", 500, [], [])
  #   send_and_keep("PREMIUM", 1000, [], [])
  #   send_and_keep("PREMIUM", 4000, [], [])

  #   send_and_keep("SALES_NAVIGATOR", 0, [], [])
  #   send_and_keep("SALES_NAVIGATOR", 10, [], [])
  #   send_and_keep("SALES_NAVIGATOR", 50, [], [])
  #   send_and_keep("SALES_NAVIGATOR", 250, [], [])
  #   send_and_keep("SALES_NAVIGATOR", 500, [], [])
  #   send_and_keep("SALES_NAVIGATOR", 1000, [], [])
  #   send_and_keep("SALES_NAVIGATOR", 4000, [], [])
  # end

  it "simulates" do
    #   simulate("STANDARD", 0, 0.2, 60)
    #   simulate("STANDARD", 300, 0.2, 60)
    #   simulate("STANDARD", 1000, 0.2, 60)
    #   simulate("SALES_NAVIGATOR", 300, 0.2, 60)
    #   simulate("SALES_NAVIGATOR", 0, 0.2, 90)
    simulate("SALES_NAVIGATOR", 1000, 0.2, 60)
  end

  # it "has sensible boundaries for no and a lot of logouts" do
  #   travel_to Time.at(60*60*24*10)
  #   send_and_keep("STANDARD", 2000, [], invoc_days(100))
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10)], invoc_days(10))
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10), Time.at(60*60*24*10)], invoc_days(10))
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10), Time.at(60*60*24*10), Time.at(60*60*24*10)], invoc_days(10))
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10), Time.at(60*60*24*10), Time.at(60*60*24*10), Time.at(60*60*24*10)], invoc_days(10))
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10), Time.at(60*60*24*10), Time.at(60*60*24*10), Time.at(60*60*24*10), Time.at(60*60*24*10)], invoc_days(10))
  # end

  # it "can deal with two logouts" do
  #   travel_to Time.at(60*60*24*10)
  #   send_and_keep("STANDARD", 2000, [], invoc_days(10))
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10), Time.at(60*60*24*10)], invoc_days(10))
  #   travel_to Time.at(60*60*24*11)
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10), Time.at(60*60*24*10)], invoc_days(11))
  #   travel_to Time.at(60*60*24*12)
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10), Time.at(60*60*24*10)], invoc_days(12))
  #   travel_to Time.at(60*60*24*13)
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10), Time.at(60*60*24*10)], invoc_days(13))
  #   travel_to Time.at(60*60*24*14)
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10), Time.at(60*60*24*10)], invoc_days(14))
  #   travel_to Time.at(60*60*24*15)
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10), Time.at(60*60*24*10)], invoc_days(15))
  #   travel_to Time.at(60*60*24*16)
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10), Time.at(60*60*24*10)], invoc_days(16))
  #   travel_to Time.at(60*60*24*17)
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10), Time.at(60*60*24*10)], invoc_days(17))
  #   travel_to Time.at(60*60*24*18)
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10), Time.at(60*60*24*10)], invoc_days(18))
  #   travel_to Time.at(60*60*24*19)
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10), Time.at(60*60*24*10)], invoc_days(19))
  #   travel_to Time.at(60*60*24*20)
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10), Time.at(60*60*24*10)], invoc_days(20))
  #   travel_to Time.at(60*60*24*21)
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10), Time.at(60*60*24*10)], invoc_days(21))
  #   travel_to Time.at(60*60*24*22)
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10), Time.at(60*60*24*10)], invoc_days(22))
  # end

  # it "can deal with one logout" do
  #   travel_to Time.at(60*60*24*10)
  #   send_and_keep("STANDARD", 2000, [], invoc_days(10))
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10)], invoc_days(10))
  #   travel_to Time.at(60*60*24*11)
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10)], invoc_days(11))
  #   travel_to Time.at(60*60*24*12)
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10)], invoc_days(12))
  #   travel_to Time.at(60*60*24*13)
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10)], invoc_days(13))
  #   travel_to Time.at(60*60*24*14)
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10)], invoc_days(14))
  #   travel_to Time.at(60*60*24*15)
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10)], invoc_days(15))
  #   travel_to Time.at(60*60*24*16)
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10)], invoc_days(16))
  #   travel_to Time.at(60*60*24*17)
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10)], invoc_days(17))
  #   travel_to Time.at(60*60*24*18)
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10)], invoc_days(18))
  #   travel_to Time.at(60*60*24*19)
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10)], invoc_days(19))
  #   travel_to Time.at(60*60*24*20)
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10)], invoc_days(20))
  #   travel_to Time.at(60*60*24*21)
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10)], invoc_days(21))
  #   travel_to Time.at(60*60*24*22)
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10)], invoc_days(22))
  #   travel_to Time.at(60*60*24*23)
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10)], invoc_days(23))
  #   travel_to Time.at(60*60*24*24)
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10)], invoc_days(24))
  #   travel_to Time.at(60*60*24*25)
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10)], invoc_days(25))
  #   travel_to Time.at(60*60*24*26)
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10)], invoc_days(26))
  #   travel_to Time.at(60*60*24*27)
  #   send_and_keep("STANDARD", 2000, [Time.at(60*60*24*10)], invoc_days(27))
  # end

  # this is a pretty internal detail but since its hard to test the validity of the result of
  # save_daily_requests we can at least thest the helper functions work as expected
  it "can compute smooth opearting days" do
    base = 1577836800
    expect(LinkedInLimits.smooth_operating_days(invoc_days(10), [])).to eq(9)
    travel_to Time.at(base + 60 * 60 * 24 * 10)
    expect(LinkedInLimits.smooth_operating_days(invoc_days(10), [Time.at(base + 60 * 60 * 24 * 10)])).to eq(9)
    travel_to Time.at(base + 60 * 60 * 24 * 11)
    expect(LinkedInLimits.smooth_operating_days(invoc_days(11), [Time.at(base + 60 * 60 * 24 * 10)])).to eq(9)
    travel_to Time.at(base + 60 * 60 * 24 * 20)
    expect(LinkedInLimits.smooth_operating_days(invoc_days(20), [Time.at(base + 60 * 60 * 24 * 10)])).to eq(9)
    travel_to Time.at(base + 60 * 60 * 24 * 21)
    expect(LinkedInLimits.smooth_operating_days(invoc_days(21), [Time.at(base + 60 * 60 * 24 * 10)])).to eq(10)

    travel_to Time.at(base + 60 * 60 * 24 * 11)
    expect(LinkedInLimits.smooth_operating_days(invoc_days(11), [Time.at(base + 60 * 60 * 24 * 10), Time.at(base + 60 * 60 * 24 * 11)])).to eq(9)
    travel_to Time.at(base + 60 * 60 * 24 * 20)
    expect(LinkedInLimits.smooth_operating_days(invoc_days(20), [Time.at(base + 60 * 60 * 24 * 10), Time.at(base + 60 * 60 * 24 * 11)])).to eq(9)
    travel_to Time.at(base + 60 * 60 * 24 * 21)
    expect(LinkedInLimits.smooth_operating_days(invoc_days(21), [Time.at(base + 60 * 60 * 24 * 10), Time.at(base + 60 * 60 * 24 * 11)])).to eq(9)
    travel_to Time.at(base + 60 * 60 * 24 * 22)
    expect(LinkedInLimits.smooth_operating_days(invoc_days(22), [Time.at(base + 60 * 60 * 24 * 10), Time.at(base + 60 * 60 * 24 * 11)])).to eq(10)

    travel_to Time.at(base + 60 * 60 * 24 * 32)
    expect(LinkedInLimits.smooth_operating_days(invoc_days(32), [Time.at(base + 60 * 60 * 24 * 10), Time.at(base + 60 * 60 * 24 * 11)])).to eq(20)

    travel_to Time.at(base + 60 * 60 * 24 * 32)
    expect(LinkedInLimits.smooth_operating_days(invoc_days(32), [Time.at(base + 60 * 60 * 24 * 10), Time.at(base + 60 * 60 * 24 * 11), Time.at(base + 60 * 60 * 24 * 32)])).to eq(20)
    travel_to Time.at(base + 60 * 60 * 24 * 42)
    expect(LinkedInLimits.smooth_operating_days(invoc_days(42), [Time.at(base + 60 * 60 * 24 * 10), Time.at(base + 60 * 60 * 24 * 11), Time.at(base + 60 * 60 * 24 * 32)])).to eq(20)
    travel_to Time.at(base + 60 * 60 * 24 * 43)
    expect(LinkedInLimits.smooth_operating_days(invoc_days(43), [Time.at(base + 60 * 60 * 24 * 10), Time.at(base + 60 * 60 * 24 * 11), Time.at(base + 60 * 60 * 24 * 32)])).to eq(21)
  end
end
