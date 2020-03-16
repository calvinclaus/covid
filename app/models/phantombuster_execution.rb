class PhantombusterExecution < ApplicationRecord
  def result_name
    Rails.env.production? ? "dashboard-pb-execution-#{id}" : "dev-dashboard-pb-execution-#{id}"
  end

  # params

  def execute
    raise "Do not call execute on non-persisted PhantombusterExecution" unless persisted?
    raise "Do not call execute again if execute succeeded once in the past" if container_id.present?

    result = HTTParty.get("https://phantombuster.com/api/v1/agent/#{agent_id}/launch",
                          query: {
                            output: "json",
                            argument: argument.merge("#{argument_key_name_for_result_name}": result_name).to_json,
                          },
                          headers: {
                            "accept": "application/json",
                            "X-Phantombuster-Key-1": ENV['PHANTOMBUSTER_API_KEY'],
                          },)

    if result["error"].present?
      update_column(:error, result["error"])
      GlobalID::Locator.locate(callback_model_global_id).phantombuster_execution_completed(self, callback_argument)
      return
    end

    update!(error: "", container_id: result["data"]["containerId"])

    MonitorPhantombusterExecution.set(wait_until: Time.now + 10.seconds).perform_later(self)
  end

  def monitor_execution
    return if container_id.blank?


    result = HTTParty.get("https://phantombuster.com/api/v1/agent/#{agent_id}/output",
                          query: {
                            mode: "track",
                            withoutResultObject: "true",
                            containerId: container_id,
                          },
                          headers: {
                            "accept": "application/json",
                            "X-Phantombuster-Key-1": ENV['PHANTOMBUSTER_API_KEY'],
                          },)


    update_column(:progress, result["data"]["progress"])

    # find a way to check for errors logged out and not a linkedin account
    if result["data"]["containerStatus"] == "not running"
      Rails.logger.silence do
        update!(
          result_csv: fetch_result_csv,
          console_output: result["data"]["output"],
          exit_code: parse_exit_code(result["data"]["output"]),
        )
        GlobalID::Locator.locate(callback_model_global_id).phantombuster_execution_completed(self, callback_argument)
      end
    else
      GlobalID::Locator.locate(callback_model_global_id).phantombuster_execution_progress(self, callback_argument)
      MonitorPhantombusterExecution.set(wait_until: Time.now + 10.seconds).perform_later(self)
    end
  end

  def parse_exit_code(console_output)
    console_output.split("(exit code: ").last.split(")").first
  end

  def fetch_result_csv
    retry_if_nil do
      result = HTTParty.get("https://phantombuster.com/api/v1/agent/#{agent_id}",
                            headers: {
                              "accept": "application/json",
                              "X-Phantombuster-Key-1": ENV['PHANTOMBUSTER_API_KEY'],
                            },)

      Rails.logger.info "Phantombuster call result #{result}"

      next "" if result["error"] == "Agent not found"
      next nil if result["status"] != "success"

      result = result["data"]

      resp = Net::HTTP.get_response(URI(
                                      "https://phantombuster.s3.amazonaws.com/#{result['userAwsFolder']}/#{result['awsFolder']}/#{result_name}.csv"
                                    ))


      return if resp.code != "200"

      resp.body.force_encoding("UTF-8").encode("UTF-8")
    end
  end

  def retry_if_nil
    max_tries = 3
    tries = 0
    res = nil
    loop do
      res = yield
      tries += 1
      break if !res.nil? || tries > max_tries

      pp "Sleeping in rety_if_nil"
      sleep(30)
    end
    res
  end

  class MonitorPhantombusterExecution < ActiveJob::Base
    queue_as :immediate

    def perform(execution)
      execution.monitor_execution
    end

    def error(_job, exception)
      ExceptionNotifier.notify_exception(exception)
    end
  end
end
