#!/usr/local/bin/ruby -w
require 'net/http'
begin
  Thread.abort_on_exception = true
  STDOUT.sync = true
  if ARGV.length != 1
    puts 'Invalid command line options: assuming development.'
    env = 'development'
  else
    env = if ARGV[0] == 'production'
            'production'
          else
            'development'
          end
  end

  pp "Env is set to #{env}"



  date_fetcher = Thread.new do
    loop do
      p "fetching data"
      system "bundle exec bin/rails runner -e #{env}  'Statistic.maybe_load_newest'"
      p "fetching date done sleeping one minute"
      sleep(60 - (Time.now + 60).strftime("%S").to_i + 1)
    end
  end

  date_fetcher.join

rescue Exception, SignalException, Interrupt => e
  p "killing all threads"
  date_fetcher.kill
  raise e
end
# rubocop:enable Lint/ShadowedException
# rubocop:enable Lint/RescueException
