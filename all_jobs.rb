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

rescue Exception, SignalException, Interrupt => e
  p "killing all threads"
  raise e
end
# rubocop:enable Lint/ShadowedException
# rubocop:enable Lint/RescueException
