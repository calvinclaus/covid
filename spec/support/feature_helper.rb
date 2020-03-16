module Support
  module FeatureHelper
    def find_element(test_id)
      page.find("[data-test-id='#{test_id}']")
    end

    RSpec::Matchers.define :have_element do |test_id|
      match do |page|
        page.has_css?("[data-test-id='#{test_id}']")
      end
      failure_message do |page|
        found_ids = page.all('[data-test-id]').map{ |el| el['data-test-id'] }
        "expected page to have element with data-test-id='#{test_id}', but only found these IDs: #{found_ids.join(', ')}"
      end
    end
  end
end
