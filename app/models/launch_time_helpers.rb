module LaunchTimeHelpers
  def distributed_daily_launch_times
    [
      [7, 10, 12, 14, 16, 18],
      [7, 9, 13, 14, 16, 18],
      [7, 9, 13, 15, 16, 18],
      [7, 10, 12, 13, 15, 17],
      [8, 10, 11, 13, 15, 17],
      [8, 11, 13, 15, 16, 18],
      [8, 9, 12, 14, 15, 18],
      [8, 10, 12, 14, 16, 18],
    ].sample
  end

  def distributed_nightly_launch_times
    [
      [23, 1, 2, 4, 5, 6],
      [22, 23, 1, 3, 5, 6],
      [0, 1, 2, 4, 5, 6],
      [23, 2, 3, 4, 5, 6],
    ].sample
  end

  # this is quite hacky. we take the persisted in db launch_times hash
  # and change the "hour" array to only include as many launch times we need for
  # the daily request target
  # we persist the launch_times because they have a random component that shouldn't be
  # changed when changes are made to the agent - to prevent accidental immediate consecutive
  # invocations for example
  # this function is untested at the moment and depends on the hours array being exactly 6 long
  # we fail to schedule more than 6 innocations in a day, i.e. dailyRequestTarget 60 is maximum reachable
  # additonal exectuions adds a buffer of additional_executions extra executions. this is useful if 50 is the daily request target but we want to launch one time more than 50 to ensure the target will be reached
  # TODO fix...?
  def pick_necessary_amount_of(launch_times, daily_request_target, additional_executions: 1)
    launch_times = launch_times.clone.with_indifferent_access
    hours = launch_times["hour"]
    reduced_hours = [hours.first]
    extra_launch_times = ((daily_request_target / 10.to_f).ceil - (2 - additional_executions)).clamp(0, 4)
    (1..extra_launch_times).each do |i|
      # start from the center
      if i < 3
        reduced_hours.push(hours[3 - i])
      else
        reduced_hours.push(hours[i])
      end
    end
    reduced_hours.push(hours.last)
    launch_times["hour"] = reduced_hours
    launch_times
  end

  def self.current_launch_time
    time = Time.current
    {
      minute: time.strftime("%M").to_i,
      hour: time.strftime("%H").to_i,
      day: time.strftime("%d").to_i,
      dow: time.strftime("%a").downcase,
      month: time.strftime("%b").downcase,
    }
  end

  def self.launch_times_include(launch_times, to_include)
    to_include = to_include.clone
    to_include[:hour] = (to_include[:hour] + (Time.now.in_time_zone(launch_times[:timezone]).utc_offset / (60 * 60))) % 24
    launch_times[:minute].include?(to_include[:minute]) &&
      launch_times[:hour].include?(to_include[:hour]) &&
      launch_times[:day].include?(to_include[:day]) &&
      launch_times[:month].include?(to_include[:month])
  end
end
